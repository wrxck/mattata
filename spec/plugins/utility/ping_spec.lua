--[[
    Tests for src/plugins/utility/ping.lua
    Tests ping and pong command responses.
]]

describe('plugins.utility.ping', function()
    local ping_plugin
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.plugins.utility.ping'] = nil
        package.loaded['socket'] = {
            gettime = function() return os.time() end,
        }

        ping_plugin = require('src.plugins.utility.ping')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('plugin metadata', function()
        it('should have name "ping"', function()
            assert.are.equal('ping', ping_plugin.name)
        end)

        it('should be in utility category', function()
            assert.are.equal('utility', ping_plugin.category)
        end)

        it('should have ping and pong commands', function()
            assert.are.same({ 'ping', 'pong' }, ping_plugin.commands)
        end)

        it('should have help text', function()
            assert.is_truthy(ping_plugin.help)
            assert.is_truthy(ping_plugin.help:match('/ping'))
        end)

        it('should have a description', function()
            assert.are.equal('Check bot responsiveness', ping_plugin.description)
        end)

        it('should not be admin_only', function()
            assert.is_falsy(ping_plugin.admin_only)
        end)

        it('should not be group_only', function()
            assert.is_falsy(ping_plugin.group_only)
        end)
    end)

    describe('on_message', function()
        it('should respond with Pong for /ping', function()
            message.command = 'ping'
            message.date = os.time()
            ping_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
            test_helper.assert_sent_message_matches(env.api, 'Pong!')
        end)

        it('should include latency in response', function()
            message.command = 'ping'
            message.date = os.time()
            ping_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, '%d+ms')
        end)

        it('should use HTML parse mode for ping', function()
            message.command = 'ping'
            message.date = os.time()
            ping_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.are.equal('html', call.args[3])
        end)

        it('should respond with snarky message for /pong', function()
            message.command = 'pong'
            ping_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
            test_helper.assert_sent_message_matches(env.api, 'extra mile')
        end)

        it('should send message to correct chat', function()
            message.command = 'ping'
            message.date = os.time()
            ping_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.are.equal(message.chat.id, call.args[1])
        end)

        it('should work in private chats', function()
            message = test_helper.make_private_message({
                text = '/ping',
            })
            message.command = 'ping'
            message.date = os.time()
            ping_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
        end)
    end)
end)
