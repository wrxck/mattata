--[[
    Tests for src/middleware/stats.lua
    Tests message counter increment, command tracking, flush to PostgreSQL.
]]

describe('middleware.stats', function()
    local stats_mw
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.middleware.stats'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        stats_mw = require('src.middleware.stats')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('name', function()
        it('should be "stats"', function()
            assert.are.equal('stats', stats_mw.name)
        end)
    end)

    describe('when message has no from or chat', function()
        it('should continue when no from', function()
            message.from = nil
            local _, should_continue = stats_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should continue when no chat', function()
            message.chat = nil
            local _, should_continue = stats_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should not increment counters when no from', function()
            message.from = nil
            stats_mw.run(ctx, message)
            assert.are.equal(0, #env.redis.commands)
        end)
    end)

    describe('message counter', function()
        it('should increment message counter in Redis', function()
            stats_mw.run(ctx, message)
            -- Check that an incr command was issued
            assert.is_true(env.redis.has_command('incr'))
        end)

        it('should use correct key format', function()
            stats_mw.run(ctx, message)
            local date = os.date('!%Y-%m-%d')
            local expected_prefix = 'stats:msg:' .. message.chat.id .. ':' .. date
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:msg:') then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should set 24h TTL on first increment', function()
            stats_mw.run(ctx, message)
            -- Find the stats key
            for k, ttl in pairs(env.redis.ttls) do
                if type(k) == 'string' and k:match('^stats:msg:') then
                    assert.are.equal(86400, ttl)
                end
            end
        end)
    end)

    describe('command tracking', function()
        it('should track command usage for / prefixed messages', function()
            message.text = '/ping'
            stats_mw.run(ctx, message)
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:cmd:ping:') then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should track command usage for ! prefixed messages', function()
            message.text = '!help'
            stats_mw.run(ctx, message)
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:cmd:help:') then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should track command usage for # prefixed messages', function()
            message.text = '#ban user'
            stats_mw.run(ctx, message)
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:cmd:ban:') then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should lowercase command names', function()
            message.text = '/PING'
            stats_mw.run(ctx, message)
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:cmd:ping:') then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should not track non-command messages', function()
            message.text = 'hello world'
            stats_mw.run(ctx, message)
            local found = false
            for k in pairs(env.redis.store) do
                if type(k) == 'string' and k:match('^stats:cmd:') then
                    found = true
                end
            end
            assert.is_false(found)
        end)

        it('should set 24h TTL on first command counter', function()
            message.text = '/ping'
            stats_mw.run(ctx, message)
            for k, ttl in pairs(env.redis.ttls) do
                if type(k) == 'string' and k:match('^stats:cmd:') then
                    assert.are.equal(86400, ttl)
                end
            end
        end)
    end)

    describe('always continues', function()
        it('should always return true', function()
            local _, should_continue = stats_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('flush()', function()
        it('should flush message stats to PostgreSQL', function()
            -- Set up some stats keys
            local date = os.date('!%Y-%m-%d')
            env.redis.set('stats:msg:-100123:' .. date .. ':456', '10')
            env.redis.set('stats:msg:-100123:' .. date .. ':789', '5')

            stats_mw.flush(env.db, env.redis)

            -- Should have executed SQL insert/upsert
            local sql_count = 0
            for _, q in ipairs(env.db.queries) do
                if q.sql and q.sql:match('message_stats') then
                    sql_count = sql_count + 1
                end
            end
            assert.is_true(sql_count > 0)
        end)

        it('should flush command stats to PostgreSQL', function()
            local date = os.date('!%Y-%m-%d')
            env.redis.set('stats:cmd:ping:-100123:' .. date, '25')

            stats_mw.flush(env.db, env.redis)

            local sql_count = 0
            for _, q in ipairs(env.db.queries) do
                if q.sql and q.sql:match('command_stats') then
                    sql_count = sql_count + 1
                end
            end
            assert.is_true(sql_count > 0)
        end)

        it('should delete Redis keys after flushing', function()
            local date = os.date('!%Y-%m-%d')
            local key = 'stats:msg:-100123:' .. date .. ':456'
            env.redis.set(key, '10')

            stats_mw.flush(env.db, env.redis)

            assert.is_nil(env.redis.store[key])
        end)

        it('should skip keys with zero count', function()
            local date = os.date('!%Y-%m-%d')
            env.redis.set('stats:msg:-100123:' .. date .. ':456', '0')

            stats_mw.flush(env.db, env.redis)

            -- Should not have executed any message_stats SQL
            local sql_count = 0
            for _, q in ipairs(env.db.queries) do
                if q.sql and q.sql:match('message_stats') then
                    sql_count = sql_count + 1
                end
            end
            assert.are.equal(0, sql_count)
        end)

        it('should handle empty stats gracefully', function()
            assert.has_no.errors(function()
                stats_mw.flush(env.db, env.redis)
            end)
        end)

        it('should use ON CONFLICT upsert SQL', function()
            local date = os.date('!%Y-%m-%d')
            env.redis.set('stats:msg:-100123:' .. date .. ':456', '10')

            stats_mw.flush(env.db, env.redis)

            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.sql and q.sql:match('ON CONFLICT') then
                    found = true
                end
            end
            assert.is_true(found)
        end)
    end)
end)
