--[[
    mattata v2.0 - Rate Limit Middleware
    Anti-spam via Redis TTL counters per user per chat.
]]

local rate_limit = {}
rate_limit.name = 'rate_limit'

local session = require('src.core.session')

local RATE_TTL = 5                -- seconds
local WARNING_THRESHOLD = 10      -- messages per TTL period
local BLOCKLIST_THRESHOLD = 25    -- messages per TTL period
local BLOCKLIST_DURATION = 86400  -- 24 hours

function rate_limit.run(ctx, message)
    if not message.from then
        return ctx, true
    end

    -- Don't rate limit global admins
    if ctx.is_global_admin then
        return ctx, true
    end

    -- Don't rate limit forwarded messages
    if message.forward_from or message.forward_from_chat then
        return ctx, true
    end

    local count = session.increment_rate(message.chat.id, message.from.id, RATE_TTL)
    ctx.message_rate = count

    if count >= BLOCKLIST_THRESHOLD and message.chat.type == 'private' then
        session.set_global_blocklist(message.from.id, BLOCKLIST_DURATION)
        local name = message.from.username and ('@' .. message.from.username) or message.from.first_name
        pcall(function()
            ctx.api.send_message(
                message.chat.id,
                string.format('Sorry, %s, but you have been blocklisted for 24 hours for spamming.', name)
            )
        end)
        return ctx, false
    elseif count == WARNING_THRESHOLD and message.chat.type == 'private' then
        local name = message.from.username and ('@' .. message.from.username) or message.from.first_name
        pcall(function()
            ctx.api.send_message(
                message.chat.id,
                string.format('Hey %s, please slow down or you\'ll be temporarily blocked!', name)
            )
        end)
    end

    return ctx, true
end

return rate_limit
