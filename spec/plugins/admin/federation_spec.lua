--[[
    Tests for federation plugins: newfed, joinfed, fban, unfban, fbaninfo.
]]

describe('plugins.admin.federation', function()
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        -- Mock shared dependencies
        package.loaded['telegram-bot-lua.tools'] = {
            escape_html = function(text)
                if not text then return '' end
                return tostring(text):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
            end,
        }
        package.loaded['src.core.logger'] = {
            debug = function() end, info = function() end,
            warn = function() end, error = function() end,
        }
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            is_enabled = function() return false end,
            bot_admins = function() return {} end,
            load = function() end, VERSION = '2.0',
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
            is_group_admin = function() return false end,
            can_restrict = function() return true end,
        }

        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('newfed', function()
        local newfed

        before_each(function()
            package.loaded['src.plugins.admin.federation.newfed'] = nil
            newfed = require('src.plugins.admin.federation.newfed')
        end)

        it('should have correct metadata', function()
            assert.are.equal('newfed', newfed.name)
            assert.are.same({ 'newfed' }, newfed.commands)
        end)

        it('should require a name argument', function()
            message.args = nil
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify a name')
        end)

        it('should require a name argument when empty string', function()
            message.args = ''
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify a name')
        end)

        it('should reject names longer than 128 characters', function()
            message.args = string.rep('a', 129)
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, '128 characters')
        end)

        it('should allow names of exactly 128 characters', function()
            message.args = string.rep('a', 128)
            env.db.queue_result({ { count = 0 } })  -- existing count
            env.db.queue_result({ { id = 'test-uuid' } })  -- insert result
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'created successfully')
        end)

        it('should reject when user already owns 5 federations', function()
            message.args = 'Test Fed'
            env.db.set_next_result({ { count = 5 } })
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'maximum')
        end)

        it('should create federation and return ID', function()
            message.args = 'My Federation'
            env.db.queue_result({ { count = 0 } })
            env.db.queue_result({ { id = 'uuid-1234' } })
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'created successfully')
            test_helper.assert_sent_message_matches(env.api, 'uuid%-1234')
        end)

        it('should handle DB failure gracefully', function()
            message.args = 'Test Fed'
            env.db.queue_result({ { count = 0 } })
            env.db.queue_result({})  -- empty result = failure
            newfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Failed')
        end)
    end)

    describe('joinfed', function()
        local joinfed

        before_each(function()
            package.loaded['src.plugins.admin.federation.joinfed'] = nil
            joinfed = require('src.plugins.admin.federation.joinfed')
        end)

        it('should have correct metadata', function()
            assert.are.equal('joinfed', joinfed.name)
            assert.is_true(joinfed.group_only)
            assert.is_true(joinfed.admin_only)
        end)

        it('should require federation ID argument', function()
            message.args = nil
            joinfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify the federation ID')
        end)

        it('should reject when chat is already in a federation', function()
            message.args = 'new-fed-id'
            env.db.set_next_result({ { id = 'old-fed-id', name = 'Old Fed' } })
            joinfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'already part')
        end)

        it('should reject when federation does not exist', function()
            message.args = 'nonexistent-id'
            env.db.queue_result({})  -- not in federation
            env.db.queue_result({})  -- federation not found
            joinfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not found')
        end)

        it('should successfully join a federation', function()
            message.args = 'fed-uuid'
            env.db.queue_result({})  -- not in federation
            env.db.queue_result({ { id = 'fed-uuid', name = 'Test Fed' } })  -- fed exists
            env.db.queue_result({ {} })  -- insert result
            joinfed.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'has joined')
        end)
    end)

    describe('fban', function()
        local fban

        before_each(function()
            package.loaded['src.plugins.admin.federation.fban'] = nil
            fban = require('src.plugins.admin.federation.fban')
        end)

        it('should have correct metadata', function()
            assert.are.equal('fban', fban.name)
            assert.are.same({ 'fban' }, fban.commands)
        end)

        it('should require chat to be in a federation', function()
            env.db.set_next_result({})  -- no federation
            fban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not part of any federation')
        end)

        it('should require federation admin/owner permission', function()
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 999 } })
            env.db.queue_result({})  -- not a fed admin
            message.from.id = 111111
            fban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'federation owner or a federation admin')
        end)

        it('should require a target user', function()
            env.db.set_next_result({ { id = 'fed-1', name = 'Fed', owner_id = message.from.id } })
            message.args = nil
            message.reply = nil
            fban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify a user')
        end)

        it('should not ban the federation owner', function()
            message.from.id = 111111
            env.db.set_next_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })
            message.reply = { from = { id = 111111, first_name = 'Owner' }, message_id = 1 }
            fban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'cannot federation%-ban the federation owner')
        end)

        it('should not ban allowlisted users', function()
            message.from.id = 111111
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })
            env.db.queue_result({ { ['1'] = 1 } })  -- is allowlisted
            message.reply = { from = { id = 222222, first_name = 'Target' }, message_id = 1 }
            fban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'allowlist')
        end)

        it('should ban user across federation chats', function()
            message.from.id = 111111
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })  -- get fed
            env.db.queue_result({})   -- not allowlisted
            env.db.queue_result({})   -- not already banned
            env.db.queue_result({})   -- insert ban
            env.db.queue_result({ { chat_id = -100111 }, { chat_id = -100222 } })  -- fed chats

            message.reply = { from = { id = 222222, first_name = 'Target' }, message_id = 1 }
            fban.on_message(env.api, message, ctx)

            assert.are.equal(2, env.api.count_calls('ban_chat_member'))
            test_helper.assert_sent_message_matches(env.api, 'Federation Ban')
        end)

        it('should invalidate Redis cache after fban', function()
            message.from.id = 111111
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })
            env.db.queue_result({})   -- not allowlisted
            env.db.queue_result({})   -- not already banned
            env.db.queue_result({})   -- insert
            env.db.queue_result({})   -- chats

            message.reply = { from = { id = 222222, first_name = 'Target' }, message_id = 1 }
            fban.on_message(env.api, message, ctx)

            test_helper.assert_redis_command(env.redis, 'del')
        end)

        it('should include reason in ban record', function()
            message.from.id = 111111
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })
            env.db.queue_result({})   -- not allowlisted
            env.db.queue_result({})   -- not already banned
            env.db.queue_result({})   -- insert
            env.db.queue_result({})   -- chats

            message.reply = { from = { id = 222222, first_name = 'Target' }, message_id = 1 }
            message.args = 'spamming links'
            fban.on_message(env.api, message, ctx)

            test_helper.assert_sent_message_matches(env.api, 'spamming links')
        end)

        it('should resolve user from username', function()
            message.from.id = 111111
            env.redis.set('username:targetuser', '333333')
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 111111 } })
            env.db.queue_result({})   -- not allowlisted
            env.db.queue_result({})   -- not already banned
            env.db.queue_result({})   -- insert
            env.db.queue_result({})   -- chats

            message.args = '@targetuser reason'
            message.reply = nil
            fban.on_message(env.api, message, ctx)

            test_helper.assert_sent_message_matches(env.api, 'Federation Ban')
        end)
    end)

    describe('unfban', function()
        local unfban

        before_each(function()
            package.loaded['src.plugins.admin.federation.unfban'] = nil
            unfban = require('src.plugins.admin.federation.unfban')
        end)

        it('should have correct metadata', function()
            assert.are.equal('unfban', unfban.name)
            assert.is_true(unfban.group_only)
        end)

        it('should require federation membership', function()
            env.db.set_next_result({})
            unfban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not part of any federation')
        end)

        it('should require federation admin permission', function()
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = 999 } })
            env.db.queue_result({})  -- not a fed admin
            message.from.id = 111111
            unfban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'federation owner or a federation admin')
        end)

        it('should require a target user', function()
            env.db.set_next_result({ { id = 'fed-1', name = 'Fed', owner_id = message.from.id } })
            message.args = nil
            message.reply = nil
            unfban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'specify a user')
        end)

        it('should report when user is not banned', function()
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = message.from.id } })
            env.db.queue_result({})  -- not banned
            message.args = '222222'
            unfban.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not banned')
        end)

        it('should unban user across federation chats', function()
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = message.from.id } })
            env.db.queue_result({ { ['1'] = 1 } })   -- is banned
            env.db.queue_result({})   -- delete ban
            env.db.queue_result({ { chat_id = -100111 }, { chat_id = -100222 } })  -- fed chats

            message.args = '222222'
            unfban.on_message(env.api, message, ctx)

            assert.are.equal(2, env.api.count_calls('unban_chat_member'))
            test_helper.assert_sent_message_matches(env.api, 'Federation Unban')
        end)

        it('should invalidate Redis cache after unfban', function()
            env.db.queue_result({ { id = 'fed-1', name = 'Fed', owner_id = message.from.id } })
            env.db.queue_result({ { ['1'] = 1 } })
            env.db.queue_result({})
            env.db.queue_result({})

            message.args = '222222'
            unfban.on_message(env.api, message, ctx)

            test_helper.assert_redis_command(env.redis, 'del')
        end)
    end)

    describe('fbaninfo', function()
        local fbaninfo

        before_each(function()
            package.loaded['src.plugins.admin.federation.fbaninfo'] = nil
            fbaninfo = require('src.plugins.admin.federation.fbaninfo')
        end)

        it('should have correct metadata', function()
            assert.are.equal('fbaninfo', fbaninfo.name)
            assert.are.same({ 'fbaninfo' }, fbaninfo.commands)
        end)

        it('should default to sender when no user specified', function()
            message.args = nil
            message.reply = nil
            ctx.is_group = true
            env.db.set_next_result({})  -- no bans found
            fbaninfo.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not banned')
        end)

        it('should show ban info for banned user (group context)', function()
            ctx.is_group = true
            env.db.set_next_result({
                {
                    reason = 'Spamming',
                    banned_by = 111111,
                    banned_at = '2024-01-01',
                    name = 'Test Fed',
                    id = 'fed-uuid',
                }
            })
            message.args = '222222'
            fbaninfo.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Federation Ban Info')
            test_helper.assert_sent_message_matches(env.api, 'Spamming')
        end)

        it('should show no-ban message for clean user', function()
            ctx.is_group = true
            env.db.set_next_result({})
            message.args = '222222'
            fbaninfo.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not banned')
        end)

        it('should resolve user from reply', function()
            ctx.is_group = true
            message.reply = { from = { id = 222222, first_name = 'Target' }, message_id = 1 }
            message.args = nil
            env.db.set_next_result({})
            fbaninfo.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not banned')
        end)

        it('should query all federations in private chat', function()
            ctx.is_group = false
            ctx.is_private = true
            message.chat.type = 'private'
            env.db.set_next_result({})
            message.args = '222222'
            fbaninfo.on_message(env.api, message, ctx)
            -- Verify it used the "all" stored procedure (not group-scoped)
            local found_private_query = false
            for _, q in ipairs(env.db.queries) do
                if q.op == 'call' and q.func_name == 'sp_get_fban_info_all' then
                    found_private_query = true
                end
            end
            assert.is_true(found_private_query)
        end)

        it('should show multiple bans', function()
            ctx.is_group = false
            ctx.is_private = true
            message.chat.type = 'private'
            env.db.set_next_result({
                { reason = 'Reason 1', name = 'Fed A', id = 'fed-1', banned_by = 111, banned_at = '2024-01-01' },
                { reason = 'Reason 2', name = 'Fed B', id = 'fed-2', banned_by = 222, banned_at = '2024-02-01' },
            })
            message.args = '222222'
            fbaninfo.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Fed A')
            test_helper.assert_sent_message_matches(env.api, 'Fed B')
        end)
    end)
end)
