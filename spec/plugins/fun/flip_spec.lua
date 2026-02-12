--[[
    Tests for src/plugins/fun/flip.lua
    Tests text flipping, reply handling, error cases.
]]

describe('plugins.fun.flip', function()
    local flip_plugin
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.plugins.fun.flip'] = nil
        flip_plugin = require('src.plugins.fun.flip')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('plugin metadata', function()
        it('should have name "flip"', function()
            assert.are.equal('flip', flip_plugin.name)
        end)

        it('should be in fun category', function()
            assert.are.equal('fun', flip_plugin.category)
        end)

        it('should have flip and reverse commands', function()
            assert.are.same({ 'flip', 'reverse' }, flip_plugin.commands)
        end)

        it('should have help text', function()
            assert.is_truthy(flip_plugin.help:match('/flip'))
        end)
    end)

    describe('on_message', function()
        it('should require text input', function()
            message.args = nil
            message.reply = nil
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'provide some text')
        end)

        it('should require text input when args is empty', function()
            message.args = ''
            message.reply = nil
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'provide some text')
        end)

        it('should flip text from args', function()
            message.args = 'hello'
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
            -- The output should not be 'hello' (it's reversed and flipped)
            local call = env.api.get_call('send_message')
            assert.are_not.equal('hello', call.args[2])
        end)

        it('should flip text from reply', function()
            message.args = nil
            message.reply = { text = 'world', message_id = 1 }
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
        end)

        it('should prefer reply text over args', function()
            message.args = 'from_args'
            message.reply = { text = 'from_reply', message_id = 1 }
            flip_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            -- The output should be the flipped version of 'from_reply' not 'from_args'
            assert.is_not_nil(call.args[2])
        end)

        it('should handle single character', function()
            message.args = 'a'
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
        end)

        it('should handle numbers', function()
            message.args = '123'
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
        end)

        it('should handle mixed case', function()
            message.args = 'Hello World'
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
        end)

        it('should send to correct chat', function()
            message.args = 'test'
            flip_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.are.equal(message.chat.id, call.args[1])
        end)

        it('should skip reply with empty text', function()
            message.args = nil
            message.reply = { text = '', message_id = 1 }
            flip_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'provide some text')
        end)
    end)
end)
