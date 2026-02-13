--[[
    mattata v2.1 - Blocklist Middleware
    Checks global bans, group bans, and SpamWatch. Stops if blocked.
]]

local blocklist = {}
blocklist.name = 'blocklist'

local config = require('src.core.config')
local session = require('src.core.session')
local logger = require('src.core.logger')

-- SpamWatch async check with Redis caching
local function check_spamwatch(ctx, user_id, token)
    -- Check cache first (positive = banned, negative = not banned)
    local ban_cached = ctx.redis.get('spamwatch:ban:' .. user_id)
    if ban_cached then
        return true
    end
    local safe_cached = ctx.redis.get('spamwatch:safe:' .. user_id)
    if safe_cached then
        return false
    end

    -- Async HTTPS check
    local ok, result = pcall(function()
        local https = require('ssl.https')
        local ltn12 = require('ltn12')
        local response_body = {}
        local _, code = https.request({
            url = 'https://api.spamwat.ch/banlist/' .. tostring(user_id),
            method = 'GET',
            sink = ltn12.sink.table(response_body),
            headers = {
                ['Authorization'] = 'Bearer ' .. token,
                ['Accept'] = 'application/json'
            }
        })
        return code
    end)

    if ok then
        if result == 200 then
            -- User is banned on SpamWatch, cache for 1 hour
            ctx.redis.setex('spamwatch:ban:' .. user_id, 3600, '1')
            return true
        else
            -- Not banned (or error), cache safe status for 1 hour
            ctx.redis.setex('spamwatch:safe:' .. user_id, 3600, '1')
            return false
        end
    else
        logger.warn('SpamWatch API error for user %s: %s', tostring(user_id), tostring(result))
        return false
    end
end

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
        local is_banned = check_spamwatch(ctx, user_id, spamwatch_token)
        if is_banned then
            ctx.is_spamwatch_banned = true
            if ctx.is_group then
                pcall(function()
                    ctx.api.ban_chat_member(message.chat.id, user_id)
                end)
            end
            return ctx, false
        end
    end

    return ctx, true
end

return blocklist
