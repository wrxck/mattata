--[[
    mattata v2.0 - Federation Middleware
    Checks if incoming users are banned in the chat's federation.
    Uses PostgreSQL as source of truth with Redis caching.
]]

local federation = {}
federation.name = 'federation'

local session = require('src.core.session')
local logger = require('src.core.logger')

function federation.run(ctx, message)
    if not ctx.is_group or not message.from then
        return ctx, true
    end

    -- Global admins bypass federation bans
    if ctx.is_global_admin then
        return ctx, true
    end

    local chat_id = message.chat.id
    local user_id = message.from.id

    -- Check if this chat belongs to a federation (cached)
    local fed_id = session.get_cached_setting(chat_id, 'federation_id', function()
        local result = ctx.db.call('sp_get_chat_federation_id', { chat_id })
        if result and #result > 0 then
            return result[1].federation_id
        end
        return nil
    end, 300)

    if not fed_id then
        return ctx, true
    end

    ctx.federation_id = fed_id

    -- Check if user is federation-banned (cached briefly)
    local ban_key = string.format('fban:%s:%s', fed_id, user_id)
    local is_banned = ctx.redis.get(ban_key)
    if is_banned == nil then
        local ban = ctx.db.call('sp_check_federation_ban', { fed_id, user_id })
        if ban and #ban > 0 then
            ctx.redis.setex(ban_key, 300, ban[1].reason or 'Federation ban')
            is_banned = ban[1].reason or 'Federation ban'
        else
            ctx.redis.setex(ban_key, 300, '__not_banned__')
            is_banned = '__not_banned__'
        end
    end

    if is_banned and is_banned ~= '__not_banned__' then
        -- Check allowlist
        local allowlist_key = string.format('fallowlist:%s:%s', fed_id, user_id)
        local is_allowed = ctx.redis.get(allowlist_key)
        if is_allowed == nil then
            local allowed = ctx.db.call('sp_check_federation_allowlist', { fed_id, user_id })
            is_allowed = (allowed and #allowed > 0) and '1' or '0'
            ctx.redis.setex(allowlist_key, 300, is_allowed)
        end
        if is_allowed ~= '1' then
            pcall(function()
                ctx.api.ban_chat_member(chat_id, user_id)
            end)
            logger.info('Federation ban enforced: user %d in chat %d (fed %s)', user_id, chat_id, fed_id)
            return ctx, false
        end
    end

    return ctx, true
end

return federation
