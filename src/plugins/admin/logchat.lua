--[[
    mattata v2.0 - Log Chat Plugin
]]

local plugin = {}
plugin.name = 'logchat'
plugin.category = 'admin'
plugin.description = 'Set a log chat for admin actions'
plugin.commands = { 'logchat' }
plugin.help = '/logchat <chat_id|off> - Sets the log chat for admin actions.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args then
        local result = ctx.db.call('sp_get_chat_setting', { message.chat.id, 'log_chat' })
        if result and #result > 0 and result[1].value then
            return api.send_message(message.chat.id, string.format(
                'Admin actions are being logged to <code>%s</code>.\nUse /logchat off to disable.',
                result[1].value
            ), { parse_mode = 'html' })
        end
        return api.send_message(message.chat.id, 'No log chat is set. Use /logchat <chat_id> to set one.')
    end

    local arg = message.args:lower()
    if arg == 'off' or arg == 'disable' or arg == 'none' then
        ctx.db.call('sp_delete_chat_setting', { message.chat.id, 'log_chat' })
        return api.send_message(message.chat.id, 'Log chat has been disabled.')
    end

    local log_chat_id = tonumber(message.args)
    if not log_chat_id then
        return api.send_message(message.chat.id, 'Please provide a valid chat ID or "off" to disable.')
    end

    -- verify bot can send to the log chat
    local test = api.send_message(log_chat_id, 'This chat has been set as the log chat for admin actions.')
    if not test then
        return api.send_message(message.chat.id, 'I can\'t send messages to that chat. Make sure I\'m a member there.')
    end

    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'log_chat', tostring(log_chat_id) })

    api.send_message(message.chat.id, string.format('Log chat set to <code>%d</code>.', log_chat_id), { parse_mode = 'html' })
end

return plugin
