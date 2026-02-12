--[[
    Tests for src/middleware/federation.lua
    Tests chat federation lookup, ban check with cache, allowlist bypass.
]]

describe('middleware.federation', function()
    local federation_mw
    local test_helper = require('spec.helpers.test_helper')
    local mock_redis = require('spec.helpers.mock_redis')
    local env, ctx, message

    before_each(function()
        package.loaded['src.middleware.federation'] = nil
        package.loaded['src.core.session'] = {
            get_cached_setting = function(chat_id, key, fetch_fn, ttl)
                local redis = env.redis
                local cache_key = string.format('cache:setting:%s:%s', tostring(chat_id), tostring(key))
                local cached = redis.get(cache_key)
                if cached ~= nil then
                    if cached == '__nil__' then return nil end
                    return cached
                end
                local value = fetch_fn()
                if value ~= nil then
                    redis.setex(cache_key, ttl or 300, tostring(value))
                else
                    redis.setex(cache_key, ttl or 300, '__nil__')
                end
                return value
            end,
        }
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        federation_mw = require('src.middleware.federation')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('name', function()
        it('should be "federation"', function()
            assert.are.equal('federation', federation_mw.name)
        end)
    end)

    describe('non-group messages', function()
        it('should pass through for private messages', function()
            ctx.is_group = false
            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('no from', function()
        it('should pass through when message has no from', function()
            message.from = nil
            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('global admin bypass', function()
        it('should bypass federation checks for global admins', function()
            ctx.is_global_admin = true
            -- Even if banned, should pass
            env.redis.set('fban:test-fed:' .. message.from.id, 'Spamming')
            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('chat not in federation', function()
        it('should pass through when chat has no federation', function()
            -- DB returns empty result for federation lookup
            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('federation ban check', function()
        it('should ban user who is federation-banned', function()
            -- Set up federation membership
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            -- Set up ban in Redis cache
            env.redis.set('fban:test-fed-uuid:' .. message.from.id, 'Spamming')
            -- No allowlist entry
            env.redis.set('fallowlist:test-fed-uuid:' .. message.from.id, '0')

            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_false(should_continue)
            test_helper.assert_api_called(env.api, 'ban_chat_member')
        end)

        it('should set federation_id in context', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            env.redis.set('fban:test-fed-uuid:' .. message.from.id, '__not_banned__')

            local new_ctx = federation_mw.run(ctx, message)
            assert.are.equal('test-fed-uuid', new_ctx.federation_id)
        end)

        it('should pass through for non-banned users', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            env.redis.set('fban:test-fed-uuid:' .. message.from.id, '__not_banned__')

            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should query DB on cache miss and cache result', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            -- No fban key cached; DB will return empty (not banned)
            env.db.set_next_result({})

            federation_mw.run(ctx, message)

            -- Should have cached the __not_banned__ result
            local ban_key = 'fban:test-fed-uuid:' .. message.from.id
            assert.are.equal('__not_banned__', env.redis.store[ban_key])
        end)

        it('should cache ban reason from DB', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            -- DB returns ban
            env.db.queue_result({ { reason = 'Spamming links' } })
            -- DB returns no allowlist
            env.db.queue_result({})

            federation_mw.run(ctx, message)

            local ban_key = 'fban:test-fed-uuid:' .. message.from.id
            assert.are.equal('Spamming links', env.redis.store[ban_key])
        end)
    end)

    describe('allowlist bypass', function()
        it('should allow banned users who are on the allowlist', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            env.redis.set('fban:test-fed-uuid:' .. message.from.id, 'Spamming')
            -- User is allowlisted
            env.redis.set('fallowlist:test-fed-uuid:' .. message.from.id, '1')

            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
            test_helper.assert_api_not_called(env.api, 'ban_chat_member')
        end)

        it('should query DB for allowlist on cache miss', function()
            env.redis.setex(
                'cache:setting:' .. message.chat.id .. ':federation_id',
                300, 'test-fed-uuid'
            )
            env.redis.set('fban:test-fed-uuid:' .. message.from.id, 'Reason')
            -- No allowlist cache
            -- DB says user IS allowlisted
            env.db.set_next_result({ { ['1'] = 1 } })

            local new_ctx, should_continue = federation_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)
end)
