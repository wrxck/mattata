--[[
    Tests for src/plugins/admin/ban.lua
    Tests target resolution (reply, args, username), admin check, bot permission check,
    ban execution, and logging.
]]

describe('plugins.admin.ban', function()
    local ban_plugin
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        -- Mock dependencies
        package.loaded['src.plugins.admin.ban'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            is_enabled = function() return false end,
            bot_admins = function() return {} end,
            load = function() end,
            VERSION = '2.0',
        }
        package.loaded['src.core.session'] = {
            get_admin_status = function() return nil end,
            set_admin_status = function() end,
            get_cached_setting = function(chat_id, key, fetch_fn, ttl)
                return fetch_fn()
            end,
        }
        package.loaded['src.core.permissions'] = {
            is_global_admin = function() return false end,
            is_group_admin = function(api, chat_id, user_id)
                -- Target user is not admin by default
                return false
            end,
            can_restrict = function(api, chat_id)
                -- Bot can restrict by default in tests
                return true
            end,
        }
        -- Mock telegram-bot-lua.tools
        package.loaded['telegram-bot-lua.tools'] = {
            escape_html = function(text)
                if not text then return '' end
                return tostring(text):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
            end,
        }

        ban_plugin = require('src.plugins.admin.ban')
        env = test_helper.setup()
        message = test_helper.make_message({
            text = '/ban',
            command = 'ban',
        })
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('plugin metadata', function()
        it('should have name "ban"', function()
            assert.are.equal('ban', ban_plugin.name)
        end)

        it('should be in admin category', function()
            assert.are.equal('admin', ban_plugin.category)
        end)

        it('should be group_only', function()
            assert.is_true(ban_plugin.group_only)
        end)

        it('should be admin_only', function()
            assert.is_true(ban_plugin.admin_only)
        end)

        it('should have ban and b commands', function()
            assert.are.same({ 'ban', 'b' }, ban_plugin.commands)
        end)

        it('should have a help string', function()
            assert.is_truthy(ban_plugin.help)
            assert.is_truthy(ban_plugin.help:match('/ban'))
        end)
    end)

    describe('bot permission check', function()
        it('should error when bot lacks restrict permission', function()
            package.loaded['src.core.permissions'].can_restrict = function() return false end
            -- Reload plugin to pick up new mock
            package.loaded['src.plugins.admin.ban'] = nil
            ban_plugin = require('src.plugins.admin.ban')

            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Ban Users')
        end)
    end)

    describe('target resolution', function()
        it('should prompt when no target specified', function()
            message.args = nil
            message.reply = nil
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify')
        end)

        it('should resolve target from reply', function()
            message.reply = {
                from = { id = 222222, first_name = 'Target' },
                message_id = 50,
            }
            message.args = nil
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'ban_chat_member')
            local call = env.api.get_call('ban_chat_member')
            assert.are.equal(222222, call.args[2])
        end)

        it('should resolve target from user ID in args', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'ban_chat_member')
        end)

        it('should resolve target from username in args', function()
            env.redis.set('username:targetuser', '333333')
            message.args = '@targetuser'
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'ban_chat_member')
            local call = env.api.get_call('ban_chat_member')
            assert.are.equal(333333, call.args[2])
        end)

        it('should extract reason from args after user ID', function()
            message.args = '222222 spamming links'
            ban_plugin.on_message(env.api, message, ctx)
            -- Check that reason was logged to DB
            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_insert_ban' then
                    found = true
                    assert.are.equal('spamming links', q.params[4])
                end
            end
            assert.is_true(found)
        end)

        it('should extract reason from args when replying', function()
            message.reply = {
                from = { id = 222222, first_name = 'Target' },
                message_id = 50,
            }
            message.args = 'being disruptive'
            ban_plugin.on_message(env.api, message, ctx)
            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_insert_ban' then
                    found = true
                    assert.are.equal('being disruptive', q.params[4])
                end
            end
            assert.is_true(found)
        end)

        it('should strip "for" prefix from reason', function()
            message.args = '222222 for spamming'
            ban_plugin.on_message(env.api, message, ctx)
            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_insert_ban' then
                    found = true
                    assert.are.equal('spamming', q.params[4])
                end
            end
            assert.is_true(found)
        end)

        it('should not ban the bot itself', function()
            message.args = tostring(env.api.info.id)
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_not_called(env.api, 'ban_chat_member')
        end)
    end)

    describe('admin target check', function()
        it('should not ban an admin', function()
            package.loaded['src.core.permissions'].is_group_admin = function(api, chat_id, user_id)
                if user_id == 222222 then return true end
                return false
            end
            package.loaded['src.plugins.admin.ban'] = nil
            ban_plugin = require('src.plugins.admin.ban')

            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_not_called(env.api, 'ban_chat_member')
            test_helper.assert_sent_message_matches(env.api, "can't ban")
        end)
    end)

    describe('ban execution', function()
        it('should call ban_chat_member with correct chat and user', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('ban_chat_member')
            assert.is_not_nil(call)
            assert.are.equal(message.chat.id, call.args[1])
            assert.are.equal(222222, call.args[2])
        end)

        it('should send success message with HTML', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            local calls = env.api.get_calls('send_message')
            -- Find the success message (not the prompt)
            local found = false
            for _, call in ipairs(calls) do
                if call.args[2]:match('has banned') then
                    found = true
                    assert.are.equal('html', call.args[3].parse_mode)
                end
            end
            assert.is_true(found)
        end)
    end)

    describe('logging', function()
        it('should log ban to bans table', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_insert_ban' then
                    found = true
                    assert.are.equal(message.chat.id, q.params[1])
                    assert.are.equal(222222, q.params[2])
                    assert.are.equal(message.from.id, q.params[3])
                end
            end
            assert.is_true(found)
        end)

        it('should log ban to admin_actions table', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            local found = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_log_admin_action' then
                    found = true
                    assert.are.equal('ban', q.params[4])
                    assert.are.equal(message.from.id, q.params[2])
                    assert.are.equal(222222, q.params[3])
                end
            end
            assert.is_true(found)
        end)
    end)

    describe('message cleanup', function()
        it('should delete the command message', function()
            message.args = '222222'
            ban_plugin.on_message(env.api, message, ctx)
            -- Should have called delete_message for the command
            local found = false
            for _, call in ipairs(env.api.calls) do
                if call.method == 'delete_message' and call.args[2] == message.message_id then
                    found = true
                end
            end
            assert.is_true(found)
        end)

        it('should delete the replied-to message', function()
            message.reply = {
                from = { id = 222222, first_name = 'Target' },
                message_id = 50,
            }
            message.args = nil
            ban_plugin.on_message(env.api, message, ctx)
            local found = false
            for _, call in ipairs(env.api.calls) do
                if call.method == 'delete_message' and call.args[2] == 50 then
                    found = true
                end
            end
            assert.is_true(found)
        end)
    end)
end)
