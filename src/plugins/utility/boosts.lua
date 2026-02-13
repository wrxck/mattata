--[[
    mattata v2.1 - Boosts Plugin
    View chat boost stats for users.
    Hooks into on_chat_boost to notify when the chat is boosted.
]]

local plugin = {}
plugin.name = 'boosts'
plugin.category = 'utility'
plugin.description = 'View chat boost info'
plugin.commands = { 'boosts', 'boost' }
plugin.help = '/boosts [user] - View boost count for yourself or a user in this chat.'
plugin.group_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    local target_id = message.from.id
    local target_name = message.from.first_name

    if message.reply and message.reply.from then
        target_id = message.reply.from.id
        target_name = message.reply.from.first_name
    elseif message.args and message.args ~= '' then
        local resolved = message.args:match('^@?(.+)$')
        local uid = tonumber(resolved) or ctx.redis.get('username:' .. resolved:lower())
        if uid then
            target_id = tonumber(uid)
            local user_info = api.get_chat(target_id)
            if user_info and user_info.result then
                target_name = user_info.result.first_name or 'User'
            end
        end
    end

    local result = api.get_user_chat_boosts(message.chat.id, target_id)
    if result and result.result and result.result.boosts then
        local boosts = result.result.boosts
        if #boosts == 0 then
            return api.send_message(message.chat.id, string.format(
                '<b>%s</b> has not boosted this chat.',
                tools.escape_html(target_name)
            ), 'html')
        end
        local lines = { string.format('<b>%s</b> has <b>%d</b> boost(s) in this chat:', tools.escape_html(target_name), #boosts) }
        for i, boost in ipairs(boosts) do
            local expire = boost.expiration_date and os.date('%Y-%m-%d', boost.expiration_date) or 'never'
            table.insert(lines, string.format('%d. Added %s, expires %s', i, os.date('%Y-%m-%d', boost.add_date), expire))
        end
        return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
    end

    return api.send_message(message.chat.id, 'Failed to retrieve boost information.')
end

-- Notify chat when it receives a new boost
function plugin.on_chat_boost(api, boost, ctx)
    if not boost.boost or not boost.boost.source then return end
    local source = boost.boost.source
    if source.user then
        local tools = require('telegram-bot-lua.tools')
        api.send_message(boost.chat.id, string.format(
            '\xF0\x9F\x9A\x80 <a href="tg://user?id=%d">%s</a> just boosted this chat!',
            source.user.id, tools.escape_html(source.user.first_name)
        ), 'html')
    end
end

return plugin
