--[[
    mattata v2.0 - Captcha Middleware
    Gates new members with captcha verification when enabled.
    The actual captcha challenge is handled by the join_captcha plugin.
    This middleware restricts unverified users from chatting.
]]

local captcha = {}
captcha.name = 'captcha'

local session = require('src.core.session')

function captcha.run(ctx, message)
    if not ctx.is_group or not message.from then
        return ctx, true
    end

    -- Fast path: single EXISTS check (avoids 2 HGET calls for 99% of messages)
    local has_captcha = ctx.redis.exists('captcha:' .. message.chat.id .. ':' .. message.from.id)
    if has_captcha ~= 1 and has_captcha ~= true then
        return ctx, true
    end

    -- Slow path: user has pending captcha, fetch details
    local pending = session.get_captcha(message.chat.id, message.from.id)
    if not pending then
        return ctx, true
    end

    -- If user has pending captcha, only allow callback query responses (handled elsewhere)
    -- Block regular messages from unverified users
    if not message.new_chat_members then
        -- Delete the message from the unverified user
        pcall(function()
            ctx.api.delete_message(message.chat.id, message.message_id)
        end)
        return ctx, false
    end

    return ctx, true
end

return captcha
