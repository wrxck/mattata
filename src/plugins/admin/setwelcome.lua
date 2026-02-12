--[[
    mattata v2.0 - Set Welcome Plugin
]]

local plugin = {}
plugin.name = 'setwelcome'
plugin.category = 'admin'
plugin.description = 'Set the welcome message for new members'
plugin.commands = { 'setwelcome', 'welcome' }
plugin.help = '/setwelcome <message> - Sets the welcome message. Placeholders: $name, $title, $id, $username, $mention'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if message.command == 'welcome' and not message.args then
        -- show current welcome message
        local result = ctx.db.call('sp_get_welcome_message', { message.chat.id })
        if not result or #result == 0 then
            return api.send_message(message.chat.id, 'No welcome message has been set. Use /setwelcome <message> to set one.')
        end
        return api.send_message(message.chat.id, '<b>Current welcome message:</b>\n\n' .. result[1].message, 'html')
    end

    if not message.args then
        return api.send_message(message.chat.id,
            'Please provide the welcome message text.\n\n'
            .. 'Placeholders: <code>$name</code>, <code>$title</code>, '
            .. '<code>$id</code>, <code>$username</code>, <code>$mention</code>',
            'html')
    end

    ctx.db.call('sp_upsert_welcome_message', { message.chat.id, message.args })

    api.send_message(message.chat.id, 'The welcome message has been updated.')
end

return plugin
