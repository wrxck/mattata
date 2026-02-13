--[[
    mattata v2.0 - Karma Plugin
    Tracks karma scores for users via +1/-1 replies.
]]

local plugin = {}
plugin.name = 'karma'
plugin.category = 'utility'
plugin.description = 'Upvote or downvote users with +1/-1 replies'
plugin.commands = { 'karma' }
plugin.help = '/karma [user] - View karma score for yourself or a replied-to user. Reply to a message with +1 or -1 to change their karma.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local target = message.from
    if message.reply and message.reply.from then
        target = message.reply.from
    elseif message.args and message.args ~= '' then
        local resolved = message.args:match('^@?(.+)$')
        local user_id = tonumber(resolved) or ctx.redis.get('username:' .. resolved:lower())
        if user_id then
            local result = api.get_chat(user_id)
            if result and result.result then
                target = result.result
            end
        end
    end
    local karma = tonumber(ctx.redis.get('karma:' .. target.id)) or 0
    local name = tools.escape_html(target.first_name or 'Unknown')
    return api.send_message(
        message.chat.id,
        string.format('%s has <b>%d</b> karma.', name, karma),
        { parse_mode = 'html' }
    )
end

function plugin.on_new_message(api, message, ctx)
    if not message.text then return end
    if not message.reply or not message.reply.from then return end
    local text = message.text:match('^%s*(.-)%s*$')
    if text ~= '+1' and text ~= '-1' then return end
    -- Prevent self-karma
    if message.from.id == message.reply.from.id then
        return api.send_message(message.chat.id, 'You can\'t modify your own karma!')
    end
    -- Prevent karma on bots
    if message.reply.from.is_bot then return end
    local tools = require('telegram-bot-lua.tools')
    local target_id = message.reply.from.id
    local key = 'karma:' .. target_id
    if text == '+1' then
        ctx.redis.incr(key)
    else
        local current = tonumber(ctx.redis.get(key)) or 0
        ctx.redis.set(key, tostring(current - 1))
    end
    local new_karma = tonumber(ctx.redis.get(key)) or 0
    local name = tools.escape_html(message.reply.from.first_name or 'Unknown')
    local arrow = text == '+1' and '/' or '\\'
    return api.send_message(
        message.chat.id,
        string.format('%s %s <b>%s</b> now has <b>%d</b> karma.', arrow, text == '+1' and 'Upvoted!' or 'Downvoted!', name, new_karma),
        { parse_mode = 'html' }
    )
end

return plugin
