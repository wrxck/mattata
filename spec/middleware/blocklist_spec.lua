--[[
    Tests for src/middleware/blocklist.lua
    Tests global blocklist, per-group blocklist, global ban, chat blocklist,
    global admin bypass, and SpamWatch integration.
]]

describe('middleware.blocklist', function()
    local blocklist
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    before_each(function()
        package.loaded['src.middleware.blocklist'] = nil
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            is_enabled = function() return false end,
            load = function() end,
            bot_admins = function() return {} end,
            VERSION = '2.0',
        }
        package.loaded['src.core.session'] = {
            is_globally_blocklisted = function(user_id)
                return env.redis.exists('global_blocklist:' .. tostring(user_id)) == 1
            end,
        }
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        blocklist = require('src.middleware.blocklist')
        env = test_helper.setup()

        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('when message has no from', function()
        it('should stop processing', function()
            message.from = nil
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_false(should_continue)
        end)
    end)

    describe('global admin bypass', function()
        it('should always allow global admins', function()
            ctx.is_global_admin = true
            env.redis.set('global_blocklist:' .. message.from.id, '1')
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('global blocklist', function()
        it('should block globally blocklisted users', function()
            env.redis.set('global_blocklist:' .. message.from.id, '1')
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_false(should_continue)
            assert.is_true(new_ctx.is_blocklisted)
        end)

        it('should allow non-blocklisted users', function()
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('global ban', function()
        it('should block globally banned users', function()
            env.redis.set('global_ban:' .. message.from.id, 'Spamming')
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_false(should_continue)
            assert.is_true(new_ctx.is_globally_banned)
        end)

        it('should auto-ban globally banned users in groups', function()
            ctx.is_group = true
            env.redis.set('global_ban:' .. message.from.id, 'Spamming')
            blocklist.run(ctx, message)
            test_helper.assert_api_called(env.api, 'ban_chat_member')
        end)

        it('should not auto-ban in private chats', function()
            ctx.is_group = false
            env.redis.set('global_ban:' .. message.from.id, 'Spamming')
            blocklist.run(ctx, message)
            test_helper.assert_api_not_called(env.api, 'ban_chat_member')
        end)
    end)

    describe('per-group blocklist', function()
        it('should block group-blocklisted users', function()
            ctx.is_group = true
            env.redis.set('group_blocklist:' .. message.chat.id .. ':' .. message.from.id, '1')
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_false(should_continue)
            assert.is_true(new_ctx.is_group_blocklisted)
        end)

        it('should allow users not on group blocklist', function()
            ctx.is_group = true
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_true(should_continue)
        end)

        it('should not check group blocklist in private chats', function()
            ctx.is_group = false
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)

    describe('blocklisted chats', function()
        it('should leave blocklisted chats', function()
            ctx.is_group = true
            env.redis.set('blocklisted_chats:' .. message.chat.id, '1')
            blocklist.run(ctx, message)
            test_helper.assert_api_called(env.api, 'leave_chat')
        end)

        it('should stop processing for blocklisted chats', function()
            ctx.is_group = true
            env.redis.set('blocklisted_chats:' .. message.chat.id, '1')
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_false(should_continue)
        end)
    end)

    describe('SpamWatch', function()
        it('should not check SpamWatch when no token configured', function()
            local new_ctx, should_continue = blocklist.run(ctx, message)
            assert.is_true(should_continue)
            assert.is_nil(new_ctx.spamwatch_checked)
        end)
    end)

    describe('name', function()
        it('should be "blocklist"', function()
            assert.are.equal('blocklist', blocklist.name)
        end)
    end)

    describe('run interface', function()
        it('should be a table with a run function', function()
            assert.are.equal('table', type(blocklist))
            assert.are.equal('function', type(blocklist.run))
        end)
    end)
end)
