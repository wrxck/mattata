--[[
    mattata v2.0 - Permissions Module
    Centralised permission checks for admin/mod/trusted roles.
    Includes bot permission checks with Redis caching.
]]

local permissions = {}

local config = require('src.core.config')
local session = require('src.core.session')

-- Cached set of global admin IDs (rebuilt every 5 minutes)
local admin_set = nil
local admin_set_expires = 0

-- Check if a user is a global bot admin
function permissions.is_global_admin(user_id)
    user_id = tonumber(user_id)
    if not user_id then
        return false
    end
    local now = os.time()
    if not admin_set or now >= admin_set_expires then
        admin_set = {}
        for _, id in ipairs(config.bot_admins()) do
            admin_set[tonumber(id)] = true
        end
        admin_set_expires = now + 300
    end
    return admin_set[user_id] or false
end

-- Force rebuild of the global admin set (e.g. after config change)
function permissions.clear_admin_cache()
    admin_set = nil
    admin_set_expires = 0
end

-- Check if a user is a group admin (Telegram admin/creator) or bot global admin
function permissions.is_group_admin(api, chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    if permissions.is_global_admin(user_id) then
        return true
    end
    -- Check cache first
    local cached = session.get_admin_status(chat_id, user_id)
    if cached ~= nil then
        return cached
    end
    -- Query Telegram API
    local member, err = api.get_chat_member(chat_id, user_id)
    if not member or not member.result then
        return false, err
    end
    local status = member.result.status
    local is_admin = (status == 'creator' or status == 'administrator')
    session.set_admin_status(chat_id, user_id, is_admin)
    return is_admin, status
end

-- Check if a user is a moderator (custom role, stored in PostgreSQL)
function permissions.is_group_mod(db, chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    local result = db.call('sp_check_group_moderator', { chat_id, user_id })
    return result and #result > 0
end

-- check if a user is trusted in a group
function permissions.is_trusted(db, chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    local result = db.call('sp_check_trusted_user', { chat_id, user_id })
    return result and #result > 0
end

-- Check if the bot has a specific permission in a chat (cached for 5 min)
-- permission: 'can_restrict_members', 'can_delete_messages', 'can_promote_members',
--             'can_pin_messages', 'can_invite_users'
function permissions.check_bot_can(api, chat_id, permission)
    if not chat_id or not permission then
        return false
    end
    -- Check cache first
    local cache_key = string.format('bot_perm:%s', permission)
    local cached = session.get_cached_setting(chat_id, cache_key, function()
        local member, _ = api.get_chat_member(chat_id, api.info.id)
        if not member or not member.result then
            return nil
        end
        if member.result.status ~= 'administrator' then
            return 'false'
        end
        return member.result[permission] and 'true' or 'false'
    end, 300)
    return cached == 'true'
end

-- Check if the bot can restrict members in a chat
function permissions.can_restrict(api, chat_id)
    return permissions.check_bot_can(api, chat_id, 'can_restrict_members')
end

-- Check if the bot can delete messages
function permissions.can_delete(api, chat_id)
    return permissions.check_bot_can(api, chat_id, 'can_delete_messages')
end

-- Check if the bot can promote members
function permissions.can_promote(api, chat_id)
    return permissions.check_bot_can(api, chat_id, 'can_promote_members')
end

-- Check if the bot can pin messages
function permissions.can_pin(api, chat_id)
    return permissions.check_bot_can(api, chat_id, 'can_pin_messages')
end

-- Check if the bot can invite users
function permissions.can_invite(api, chat_id)
    return permissions.check_bot_can(api, chat_id, 'can_invite_users')
end

-- Check if a user has admin OR mod rights
function permissions.is_admin_or_mod(api, db, chat_id, user_id)
    if permissions.is_group_admin(api, chat_id, user_id) then
        return true
    end
    return permissions.is_group_mod(db, chat_id, user_id)
end

return permissions
