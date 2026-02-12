--[[
    Tests for src/middleware/captcha.lua
    Tests pending captcha blocking, no captcha pass-through.
]]

describe('middleware.captcha', function()
    local captcha_mw
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.middleware.captcha'] = nil
        package.loaded['src.core.session'] = {
            get_captcha = function(chat_id, user_id)
                local redis = env.redis
                local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
                local text = redis.hget(hash, 'text')
                if not text then return nil end
                return { text = text, message_id = redis.hget(hash, 'id') }
            end,
        }

        captcha_mw = require('src.middleware.captcha')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('name', function()
        it('should be "captcha"', function()
            assert.are.equal('captcha', captcha_mw.name)
        end)
    end)

    describe('non-group messages', function()
        it('should pass through for private messages', function()
            ctx.is_group = false
            local _, should_continue = captcha_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('no from', function()
        it('should pass through when no from', function()
            message.from = nil
            local _, should_continue = captcha_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('no pending captcha', function()
        it('should pass through when user has no pending captcha', function()
            local _, should_continue = captcha_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('pending captcha', function()
        before_each(function()
            -- Set up a pending captcha
            local hash = string.format('chat:%s:captcha:%s', message.chat.id, message.from.id)
            env.redis.hset(hash, 'text', 'ABCD')
            env.redis.hset(hash, 'id', '42')
        end)

        it('should block regular messages from unverified users', function()
            local _, should_continue = captcha_mw.run(ctx, message)
            assert.is_false(should_continue)
        end)

        it('should delete blocked messages', function()
            captcha_mw.run(ctx, message)
            test_helper.assert_api_called(env.api, 'delete_message')
        end)

        it('should delete the correct message', function()
            message.message_id = 99
            captcha_mw.run(ctx, message)
            local call = env.api.get_call('delete_message')
            assert.are.equal(message.chat.id, call.args[1])
            assert.are.equal(99, call.args[2])
        end)

        it('should allow new_chat_members messages even with pending captcha', function()
            message.new_chat_members = { { id = message.from.id } }
            local _, should_continue = captcha_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should not delete new_chat_members messages', function()
            message.new_chat_members = { { id = message.from.id } }
            captcha_mw.run(ctx, message)
            test_helper.assert_api_not_called(env.api, 'delete_message')
        end)
    end)

    describe('run interface', function()
        it('should be a valid middleware', function()
            assert.are.equal('table', type(captcha_mw))
            assert.are.equal('function', type(captcha_mw.run))
        end)
    end)
end)
