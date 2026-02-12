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
        local result = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'log_chat'",
            { message.chat.id }
        )
        if result and #result > 0 and result[1].value then
            return api.send_message(message.chat.id, string.format(
                'Admin actions are being logged to <code>%s</code>.\nUse /logchat off to disable.',
                result[1].value
            ), 'html')
        end
        return api.send_message(message.chat.id, 'No log chat is set. Use /logchat <chat_id> to set one.')
    end

    local arg = message.args:lower()
    if arg == 'off' or arg == 'disable' or arg == 'none' then
        ctx.db.execute(
            "DELETE FROM chat_settings WHERE chat_id = $1 AND key = 'log_chat'",
            { message.chat.id }
        )
        return api.send_message(message.chat.id, 'Log chat has been disabled.')
    end

    local log_chat_id = tonumber(message.args)
    if not log_chat_id then
        return api.send_message(message.chat.id, 'Please provide a valid chat ID or "off" to disable.')
    end

    -- Verify bot can send to the log chat
    local test = api.send_message(log_chat_id, 'This chat has been set as the log chat for admin actions.', nil, nil, nil, nil, nil)
    if not test then
        return api.send_message(message.chat.id, 'I can\'t send messages to that chat. Make sure I\'m a member there.')
    end

    ctx.db.upsert('chat_settings', {
        chat_id = message.chat.id,
        key = 'log_chat',
        value = tostring(log_chat_id)
    }, { 'chat_id', 'key' }, { 'value' })

    api.send_message(message.chat.id, string.format('Log chat set to <code>%d</code>.', log_chat_id), 'html')
end

return plugin
