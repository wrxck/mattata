--[[
    Tests for src/middleware/user_tracker.lua
    Tests debouncing, upsert on first message, username mapping.
]]

describe('middleware.user_tracker', function()
    local user_tracker
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.middleware.user_tracker'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        user_tracker = require('src.middleware.user_tracker')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('name', function()
        it('should be "user_tracker"', function()
            assert.are.equal('user_tracker', user_tracker.name)
        end)
    end)

    describe('when message has no from', function()
        it('should continue processing', function()
            message.from = nil
            local new_ctx, should_continue = user_tracker.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('debouncing', function()
        it('should skip DB upsert when dedup key exists', function()
            -- Set dedup key to simulate recent activity
            local dedup_key = string.format('seen:%s:%s', message.from.id, message.chat.id)
            env.redis.set(dedup_key, '1')

            user_tracker.run(ctx, message)

            -- Should NOT have done any upserts
            local upsert_count = 0
            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' then upsert_count = upsert_count + 1 end
            end
            assert.are.equal(0, upsert_count)
        end)

        it('should still update username mapping when debounced', function()
            local dedup_key = string.format('seen:%s:%s', message.from.id, message.chat.id)
            env.redis.set(dedup_key, '1')

            user_tracker.run(ctx, message)

            -- Should have set username mapping
            assert.is_not_nil(env.redis.store['username:testuser'])
        end)

        it('should upsert on first message (no dedup key)', function()
            user_tracker.run(ctx, message)

            -- Should have upserted user
            local user_upserted = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'users' then
                    user_upserted = true
                end
            end
            assert.is_true(user_upserted)
        end)

        it('should set dedup key with 60s TTL', function()
            user_tracker.run(ctx, message)

            local dedup_key = string.format('seen:%s:%s', message.from.id, message.chat.id)
            assert.is_not_nil(env.redis.store[dedup_key])
            assert.are.equal(60, env.redis.ttls[dedup_key])
        end)
    end)

    describe('user upsert', function()
        it('should upsert user data to PostgreSQL', function()
            user_tracker.run(ctx, message)

            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'users' then
                    found = true
                    assert.are.equal(message.from.id, q.data.user_id)
                    assert.are.equal('testuser', q.data.username)
                    assert.are.equal('Test', q.data.first_name)
                end
            end
            assert.is_true(found)
        end)

        it('should handle users without username', function()
            message.from.username = nil
            user_tracker.run(ctx, message)

            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'users' then
                    assert.is_nil(q.data.username)
                end
            end
        end)

        it('should lowercase username', function()
            message.from.username = 'TestUser'
            user_tracker.run(ctx, message)

            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'users' then
                    assert.are.equal('testuser', q.data.username)
                end
            end
        end)

        it('should use correct conflict and update keys', function()
            user_tracker.run(ctx, message)

            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'users' then
                    assert.are.same({ 'user_id' }, q.conflict_keys)
                    -- Update keys should include username, first_name, etc.
                    local has_username = false
                    for _, k in ipairs(q.update_keys) do
                        if k == 'username' then has_username = true end
                    end
                    assert.is_true(has_username)
                end
            end
        end)
    end)

    describe('chat upsert', function()
        it('should upsert chat data for group messages', function()
            user_tracker.run(ctx, message)

            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'chats' then
                    found = true
                    assert.are.equal(message.chat.id, q.data.chat_id)
                    assert.are.equal('Test Group', q.data.title)
                end
            end
            assert.is_true(found)
        end)

        it('should not upsert chat for private messages', function()
            message.chat.type = 'private'
            user_tracker.run(ctx, message)

            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'chats' then
                    assert.fail('should not upsert chat for private messages')
                end
            end
        end)

        it('should track user-chat membership', function()
            user_tracker.run(ctx, message)

            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'upsert' and q.table_name == 'chat_members' then
                    found = true
                    assert.are.equal(message.chat.id, q.data.chat_id)
                    assert.are.equal(message.from.id, q.data.user_id)
                end
            end
            assert.is_true(found)
        end)
    end)

    describe('username mapping', function()
        it('should set username -> user_id mapping in Redis', function()
            user_tracker.run(ctx, message)
            local stored_id = env.redis.store['username:testuser']
            assert.is_not_nil(stored_id)
            assert.are.equal(tostring(message.from.id), stored_id)
        end)

        it('should not set mapping when username is nil', function()
            message.from.username = nil
            user_tracker.run(ctx, message)
            -- No username:* key should exist
            local found = false
            for k in pairs(env.redis.store) do
                if k:match('^username:') then found = true end
            end
            assert.is_false(found)
        end)

        it('should lowercase username in mapping', function()
            message.from.username = 'TestUser'
            user_tracker.run(ctx, message)
            assert.is_not_nil(env.redis.store['username:testuser'])
            assert.is_nil(env.redis.store['username:TestUser'])
        end)
    end)

    describe('always continues', function()
        it('should always return true for should_continue', function()
            local _, should_continue = user_tracker.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)
end)
