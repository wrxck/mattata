--[[
    mattata v2.1 - Custom Title Plugin
    Set custom admin titles.
]]

local plugin = {}
plugin.name = 'customtitle'
plugin.category = 'admin'
plugin.description = 'Set admin custom title'
plugin.commands = { 'customtitle', 'title' }
plugin.help = '/customtitle <title> - Set a custom title for an admin. Reply to a user or pass their ID/username.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_promote(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Promote Members" admin permission to use this command.')
    end

    local target_id
    local title

    if message.reply and message.reply.from then
        target_id = message.reply.from.id
        title = message.args
    elseif message.args then
        local id_or_user, rest = message.args:match('^(%S+)%s+(.+)$')
        if id_or_user then
            target_id = tonumber(id_or_user) or ctx.redis.get('username:' .. id_or_user:lower():gsub('^@', ''))
            title = rest
        end
    end

    if not target_id or not title or title == '' then
        return api.send_message(message.chat.id, 'Usage: Reply to an admin with /customtitle <title>, or use /customtitle <user> <title>')
    end

    if #title > 16 then
        return api.send_message(message.chat.id, 'Custom title must be 16 characters or less.')
    end

    local result = api.set_chat_administrator_custom_title(message.chat.id, target_id, title)
    if result then
        return api.send_message(message.chat.id, string.format(
            'Custom title for <a href="tg://user?id=%s">this admin</a> set to: <b>%s</b>',
            tostring(target_id), tools.escape_html(title)
        ), 'html')
    end
    return api.send_message(message.chat.id, 'Failed to set custom title. The user must be an admin promoted by me.')
end

return plugin
