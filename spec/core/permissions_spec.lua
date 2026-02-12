--[[
    Tests for src/core/permissions.lua
    Tests is_global_admin, is_group_admin (with cache), check_bot_can,
    can_restrict, can_delete, can_pin, is_admin_or_mod.
]]

describe('core.permissions', function()
    local permissions
    local mock_api_mod = require('spec.helpers.mock_api')
    local mock_redis = require('spec.helpers.mock_redis')
    local mock_db = require('spec.helpers.mock_db')
    local api, redis, db

    before_each(function()
        -- Reset modules to get fresh state
        package.loaded['src.core.permissions'] = nil
        package.loaded['src.core.session'] = nil
        package.loaded['src.core.config'] = nil

        -- Mock config to return known admin list
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            get_number = function(key, default) return default end,
            is_enabled = function(key) return false end,
            bot_admins = function() return { 221714512, 99999 } end,
            bot_name = function() return 'mattata' end,
            get_list = function(key) return { 221714512, 99999 } end,
            load = function() end,
            VERSION = '2.0',
        }

        redis = mock_redis.new()

        -- Init session with our mock redis
        local session = require('src.core.session')
        session.init(redis)

        permissions = require('src.core.permissions')
        api = mock_api_mod.new()
        db = mock_db.new()
    end)

    after_each(function()
        api.reset()
        redis.reset()
        db.reset()
    end)

    describe('is_global_admin()', function()
        it('should return true for a global admin', function()
            assert.is_true(permissions.is_global_admin(221714512))
        end)

        it('should return true for second global admin', function()
            assert.is_true(permissions.is_global_admin(99999))
        end)

        it('should return false for non-admin', function()
            assert.is_false(permissions.is_global_admin(111111))
        end)

        it('should return false for nil', function()
            assert.is_false(permissions.is_global_admin(nil))
        end)

        it('should handle string user_id by converting to number', function()
            assert.is_true(permissions.is_global_admin('221714512'))
        end)

        it('should return false for non-numeric string', function()
            assert.is_false(permissions.is_global_admin('abc'))
        end)
    end)

    describe('is_group_admin()', function()
        it('should return true for global admin without API call', function()
            local result = permissions.is_group_admin(api, -100123, 221714512)
            assert.is_true(result)
            -- Should not have called get_chat_member since user is global admin
            assert.are.equal(0, api.count_calls('get_chat_member'))
        end)

        it('should return true for Telegram administrator', function()
            api.set_admin(-100123, 456)
            local result = permissions.is_group_admin(api, -100123, 456)
            assert.is_true(result)
        end)

        it('should return true for chat creator', function()
            api.set_creator(-100123, 789)
            local result = permissions.is_group_admin(api, -100123, 789)
            assert.is_true(result)
        end)

        it('should return false for regular member', function()
            local result = permissions.is_group_admin(api, -100123, 111)
            assert.is_false(result)
        end)

        it('should cache admin status in session', function()
            api.set_admin(-100123, 456)
            permissions.is_group_admin(api, -100123, 456)
            -- Second call should use cache, not API
            api.reset()
            local result = permissions.is_group_admin(api, -100123, 456)
            assert.is_true(result)
            assert.are.equal(0, api.count_calls('get_chat_member'))
        end)

        it('should cache non-admin status too', function()
            permissions.is_group_admin(api, -100123, 111)
            api.reset()
            local result = permissions.is_group_admin(api, -100123, 111)
            assert.is_false(result)
            assert.are.equal(0, api.count_calls('get_chat_member'))
        end)

        it('should return false when chat_id is nil', function()
            assert.is_false(permissions.is_group_admin(api, nil, 456))
        end)

        it('should return false when user_id is nil', function()
            assert.is_false(permissions.is_group_admin(api, -100123, nil))
        end)
    end)

    describe('is_group_mod()', function()
        it('should return true when user has moderator role', function()
            db.set_next_result({ { ['1'] = 1 } })
            assert.is_true(permissions.is_group_mod(db, -100123, 456))
        end)

        it('should return false when user is not a moderator', function()
            db.set_next_result({})
            assert.is_false(permissions.is_group_mod(db, -100123, 456))
        end)

        it('should return false for nil chat_id', function()
            assert.is_false(permissions.is_group_mod(db, nil, 456))
        end)

        it('should return false for nil user_id', function()
            assert.is_false(permissions.is_group_mod(db, -100123, nil))
        end)

        it('should query the correct SQL', function()
            db.set_next_result({})
            permissions.is_group_mod(db, -100123, 456)
            assert.is_true(db.has_query('chat_members'))
            assert.is_true(db.has_query('moderator'))
        end)
    end)

    describe('is_trusted()', function()
        it('should return true when user has trusted role', function()
            db.set_next_result({ { ['1'] = 1 } })
            assert.is_true(permissions.is_trusted(db, -100123, 456))
        end)

        it('should return false when user is not trusted', function()
            db.set_next_result({})
            assert.is_false(permissions.is_trusted(db, -100123, 456))
        end)
    end)

    describe('check_bot_can()', function()
        it('should return true when bot has the permission', function()
            api.set_bot_admin(-100123, { can_restrict_members = true })
            local result = permissions.check_bot_can(api, -100123, 'can_restrict_members')
            assert.is_true(result)
        end)

        it('should return false when bot lacks the permission', function()
            api.set_bot_admin(-100123, { can_restrict_members = false })
            local result = permissions.check_bot_can(api, -100123, 'can_restrict_members')
            assert.is_false(result)
        end)

        it('should return false when bot is not an admin', function()
            -- Default: bot is a regular member
            local result = permissions.check_bot_can(api, -100123, 'can_restrict_members')
            assert.is_false(result)
        end)

        it('should cache the result', function()
            api.set_bot_admin(-100123, { can_restrict_members = true })
            permissions.check_bot_can(api, -100123, 'can_restrict_members')
            api.reset()
            local result = permissions.check_bot_can(api, -100123, 'can_restrict_members')
            assert.is_true(result)
            assert.are.equal(0, api.count_calls('get_chat_member'))
        end)

        it('should return false for nil chat_id', function()
            assert.is_false(permissions.check_bot_can(api, nil, 'can_restrict_members'))
        end)

        it('should return false for nil permission', function()
            assert.is_false(permissions.check_bot_can(api, -100123, nil))
        end)
    end)

    describe('convenience permission checks', function()
        it('can_restrict should check can_restrict_members', function()
            api.set_bot_admin(-100123, { can_restrict_members = true })
            assert.is_true(permissions.can_restrict(api, -100123))
        end)

        it('can_delete should check can_delete_messages', function()
            api.set_bot_admin(-100123, { can_delete_messages = true })
            assert.is_true(permissions.can_delete(api, -100123))
        end)

        it('can_pin should check can_pin_messages', function()
            api.set_bot_admin(-100123, { can_pin_messages = true })
            assert.is_true(permissions.can_pin(api, -100123))
        end)

        it('can_promote should check can_promote_members', function()
            api.set_bot_admin(-100123, { can_promote_members = true })
            assert.is_true(permissions.can_promote(api, -100123))
        end)

        it('can_invite should check can_invite_users', function()
            api.set_bot_admin(-100123, { can_invite_users = true })
            assert.is_true(permissions.can_invite(api, -100123))
        end)
    end)

    describe('is_admin_or_mod()', function()
        it('should return true for admin', function()
            api.set_admin(-100123, 456)
            assert.is_true(permissions.is_admin_or_mod(api, db, -100123, 456))
        end)

        it('should return true for moderator', function()
            db.set_next_result({ { ['1'] = 1 } })
            assert.is_true(permissions.is_admin_or_mod(api, db, -100123, 789))
        end)

        it('should return false for regular user', function()
            db.set_next_result({})
            assert.is_false(permissions.is_admin_or_mod(api, db, -100123, 111))
        end)

        it('should return true for global admin', function()
            assert.is_true(permissions.is_admin_or_mod(api, db, -100123, 221714512))
        end)
    end)
end)
