--[[
    Tests for src/middleware/rate_limit.lua
    Tests counter increment, warning threshold, blocklist threshold.
]]

describe('middleware.rate_limit', function()
    local rate_limit
    local test_helper = require('spec.helpers.test_helper')
    local mock_redis = require('spec.helpers.mock_redis')
    local env, ctx, message

    -- We need to mock session module to use our redis
    local increment_rate_count = {}

    before_each(function()
        package.loaded['src.middleware.rate_limit'] = nil
        package.loaded['src.core.session'] = {
            increment_rate = function(chat_id, user_id, ttl)
                local key = tostring(chat_id) .. ':' .. tostring(user_id)
                increment_rate_count[key] = (increment_rate_count[key] or 0) + 1
                return increment_rate_count[key]
            end,
            set_global_blocklist = function(user_id, duration)
                -- Track blocklist calls
                _G._blocklist_set = { user_id = user_id, duration = duration }
            end,
        }
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        rate_limit = require('src.middleware.rate_limit')
        env = test_helper.setup()
        increment_rate_count = {}
        _G._blocklist_set = nil

        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
        _G._blocklist_set = nil
    end)

    describe('name', function()
        it('should be "rate_limit"', function()
            assert.are.equal('rate_limit', rate_limit.name)
        end)
    end)

    describe('when message has no from', function()
        it('should continue processing', function()
            message.from = nil
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('global admin bypass', function()
        it('should not rate limit global admins', function()
            ctx.is_global_admin = true
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('forwarded messages', function()
        it('should not rate limit forwarded messages (forward_from)', function()
            message.forward_from = { id = 999 }
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should not rate limit forwarded messages (forward_from_chat)', function()
            message.forward_from_chat = { id = -100999 }
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('counter increment', function()
        it('should increment the rate counter', function()
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
            assert.are.equal(1, new_ctx.message_rate)
        end)

        it('should track rate in context', function()
            local new_ctx = rate_limit.run(ctx, message)
            assert.is_not_nil(new_ctx.message_rate)
        end)
    end)

    describe('warning threshold (10)', function()
        it('should send warning at threshold in private chat', function()
            message.chat.type = 'private'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 9  -- Next increment will be 10
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
            test_helper.assert_api_called(env.api, 'send_message')
        end)

        it('should not send warning below threshold', function()
            message.chat.type = 'private'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 4  -- Next increment will be 5
            rate_limit.run(ctx, message)
            test_helper.assert_api_not_called(env.api, 'send_message')
        end)

        it('should not send warning in group chats', function()
            message.chat.type = 'supergroup'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 9  -- Next will be 10
            rate_limit.run(ctx, message)
            test_helper.assert_api_not_called(env.api, 'send_message')
        end)

        it('should include username in warning message', function()
            message.chat.type = 'private'
            message.from.username = 'testuser'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 9
            rate_limit.run(ctx, message)
            test_helper.assert_sent_message_matches(env.api, '@testuser')
        end)

        it('should use first_name when no username', function()
            message.chat.type = 'private'
            message.from.username = nil
            message.from.first_name = 'Alice'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 9
            rate_limit.run(ctx, message)
            test_helper.assert_sent_message_matches(env.api, 'Alice')
        end)
    end)

    describe('blocklist threshold (25)', function()
        it('should blocklist user at threshold in private chat', function()
            message.chat.type = 'private'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 24  -- Next increment will be 25
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_false(should_continue)
            assert.is_not_nil(_G._blocklist_set)
            assert.are.equal(message.from.id, _G._blocklist_set.user_id)
        end)

        it('should blocklist for 24 hours', function()
            message.chat.type = 'private'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 24
            rate_limit.run(ctx, message)
            assert.are.equal(86400, _G._blocklist_set.duration)
        end)

        it('should send blocklist notification', function()
            message.chat.type = 'private'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 24
            rate_limit.run(ctx, message)
            test_helper.assert_api_called(env.api, 'send_message')
            test_helper.assert_sent_message_matches(env.api, 'blocklisted')
        end)

        it('should not blocklist in group chats', function()
            message.chat.type = 'supergroup'
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 24
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
            assert.is_nil(_G._blocklist_set)
        end)
    end)

    describe('normal operation', function()
        it('should allow messages below thresholds', function()
            local key = tostring(message.chat.id) .. ':' .. tostring(message.from.id)
            increment_rate_count[key] = 2  -- Next will be 3
            local new_ctx, should_continue = rate_limit.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)
end)
