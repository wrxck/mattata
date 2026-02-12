--[[
    mattata v2.0 - Blocklist Middleware
    Checks global bans, group bans, and SpamWatch. Stops if blocked.
]]

local blocklist = {}
blocklist.name = 'blocklist'

local config = require('src.core.config')
local session = require('src.core.session')
local logger = require('src.core.logger')

function blocklist.run(ctx, message)
    if not message.from then
        return ctx, false
    end

    local user_id = message.from.id

    -- Global admins are never blocked
    if ctx.is_global_admin then
        return ctx, true
    end

    -- Check global blocklist
    if session.is_globally_blocklisted(user_id) then
        ctx.is_blocklisted = true
        return ctx, false
    end

    -- Check global ban (federation-level)
    local global_ban = ctx.redis.get('global_ban:' .. user_id)
    if global_ban then
        ctx.is_globally_banned = true
        -- Auto-ban in groups
        if ctx.is_group then
            pcall(function()
                ctx.api.ban_chat_member(message.chat.id, user_id)
            end)
        end
        return ctx, false
    end

    -- Check per-group blocklist
    if ctx.is_group then
        local group_blocked = ctx.redis.get('group_blocklist:' .. message.chat.id .. ':' .. user_id)
        if group_blocked then
            ctx.is_group_blocklisted = true
            return ctx, false
        end

        -- Check blocklisted chats
        local chat_blocked = ctx.redis.get('blocklisted_chats:' .. message.chat.id)
        if chat_blocked then
            pcall(function()
                ctx.api.leave_chat(message.chat.id)
            end)
            return ctx, false
        end
    end

    -- SpamWatch check (if configured)
    local spamwatch_token = config.get('SPAMWATCH_TOKEN')
    if spamwatch_token and spamwatch_token ~= '' then
        local cached = ctx.redis.get('not_blocklisted:' .. user_id)
        if not cached then
            -- Check will be done asynchronously in future; for now just mark as not checked
            ctx.spamwatch_checked = false
        end
    end

    return ctx, true
end

return blocklist
