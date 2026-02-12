--[[
    Tests for src/plugins/utility/help.lua
    Tests help display, per-command help, callback navigation.
]]

describe('plugins.utility.help', function()
    local help_plugin
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.plugins.utility.help'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end, info = function() end,
            warn = function() end, error = function() end,
        }
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            is_enabled = function() return false end,
            bot_admins = function() return {} end,
            bot_name = function() return 'mattata' end,
            load = function() end, VERSION = '2.0',
        }
        package.loaded['telegram-bot-lua.tools'] = {
            escape_html = function(text)
                if not text then return '' end
                return tostring(text):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
            end,
        }

        -- Mock loader
        package.loaded['src.core.loader'] = {
            get_by_command = function(cmd)
                if cmd == 'ping' then
                    return { name = 'ping', help = '/ping - PONG!', commands = { 'ping' } }
                end
                return nil
            end,
            get_help = function(category)
                if category == 'admin' then
                    return {
                        { name = 'ban', category = 'admin', commands = { 'ban' }, help = '/ban', description = 'Ban users' },
                    }
                end
                return {
                    { name = 'ping', category = 'utility', commands = { 'ping' }, help = '/ping', description = 'Ping' },
                    { name = 'help', category = 'utility', commands = { 'help' }, help = '/help', description = 'Help' },
                }
            end,
        }
        package.loaded['src.core.permissions'] = {
            is_group_admin = function() return false end,
        }

        help_plugin = require('src.plugins.utility.help')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('plugin metadata', function()
        it('should have name "help"', function()
            assert.are.equal('help', help_plugin.name)
        end)

        it('should have help and start commands', function()
            assert.are.same({ 'help', 'start' }, help_plugin.commands)
        end)

        it('should be permanent', function()
            assert.is_true(help_plugin.permanent)
        end)

        it('should be in utility category', function()
            assert.are.equal('utility', help_plugin.category)
        end)
    end)

    describe('on_message', function()
        it('should show main help menu without args', function()
            message.args = nil
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
            test_helper.assert_sent_message_matches(env.api, 'feature%-rich')
        end)

        it('should include user first name', function()
            message.args = nil
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Test')
        end)

        it('should include bot name', function()
            message.args = nil
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Test Bot')
        end)

        it('should show specific command help when args provided', function()
            message.args = 'ping'
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'PONG')
        end)

        it('should handle /help with / prefix in args', function()
            message.args = '/ping'
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'PONG')
        end)

        it('should show "not found" for unknown command', function()
            message.args = 'nonexistent'
            help_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'No plugin found')
        end)

        it('should use HTML parse mode', function()
            message.args = nil
            help_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.are.equal('html', call.args[3])
        end)
    end)

    describe('on_callback_query', function()
        local callback_query, cb_message

        before_each(function()
            callback_query = test_helper.make_callback_query()
            cb_message = callback_query.message
        end)

        it('should handle cmds page navigation', function()
            callback_query.data = 'cmds:1'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
        end)

        it('should handle admin cmds page navigation', function()
            callback_query.data = 'acmds:1'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
        end)

        it('should handle links callback', function()
            callback_query.data = 'links'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
        end)

        it('should handle back callback', function()
            callback_query.data = 'back'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
        end)

        it('should handle noop callback', function()
            callback_query.data = 'noop'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'answer_callback_query')
        end)

        it('should handle settings callback', function()
            callback_query.data = 'settings'
            cb_message.chat.type = 'supergroup'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            -- Non-admin should get "you need to be an admin" callback
            test_helper.assert_api_called(env.api, 'answer_callback_query')
        end)

        it('should allow admin to access settings', function()
            package.loaded['src.core.permissions'].is_group_admin = function() return true end
            package.loaded['src.plugins.utility.help'] = nil
            help_plugin = require('src.plugins.utility.help')

            callback_query.data = 'settings'
            cb_message.chat.type = 'supergroup'
            help_plugin.on_callback_query(env.api, callback_query, cb_message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_reply_markup')
        end)
    end)
end)
