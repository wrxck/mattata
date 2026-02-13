--[[
    mattata v2.0 - Report Plugin
]]

local plugin = {}
plugin.name = 'report'
plugin.category = 'admin'
plugin.description = 'Report a user to group admins'
plugin.commands = { 'report' }
plugin.help = '/report - Reports the replied-to user to all group admins.'
plugin.group_only = true
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.reply or not message.reply.from then
        return api.send_message(message.chat.id, 'Please reply to the message of the user you want to report.')
    end
    local reported_id = message.reply.from.id
    if reported_id == message.from.id then
        return api.send_message(message.chat.id, 'You can\'t report yourself.')
    end
    if reported_id == api.info.id then
        return api.send_message(message.chat.id, 'You can\'t report me.')
    end

    -- Get chat administrators
    local admins = api.get_chat_administrators(message.chat.id)
    if not admins or not admins.result then
        return api.send_message(message.chat.id, 'I couldn\'t retrieve the list of admins.')
    end

    local mentions = {}
    for _, admin in ipairs(admins.result) do
        if not admin.user.is_bot then
            table.insert(mentions, string.format(
                '<a href="tg://user?id=%d">%s</a>',
                admin.user.id,
                tools.escape_html(admin.user.first_name)
            ))
        end
    end

    local reporter_name = tools.escape_html(message.from.first_name)
    local reported_name = tools.escape_html(message.reply.from.first_name)
    local reason = message.args and ('\nReason: ' .. tools.escape_html(message.args)) or ''

    local output = string.format(
        '<a href="tg://user?id=%d">%s</a> has reported <a href="tg://user?id=%d">%s</a> to the admins.%s\n\n%s',
        message.from.id, reporter_name,
        reported_id, reported_name,
        reason,
        table.concat(mentions, ', ')
    )

    api.send_message(message.chat.id, output, { parse_mode = 'html', reply_parameters = { message_id = message.reply.message_id } })
end

return plugin
