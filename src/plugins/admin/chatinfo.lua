--[[
    mattata v2.1 - Chat Info Plugin
    Set chat title and description.
]]

local plugin = {}
plugin.name = 'chatinfo'
plugin.category = 'admin'
plugin.description = 'Set chat title or description'
plugin.commands = { 'settitle', 'setdescription' }
plugin.help = '/settitle <title> - Set the chat title.\n/setdescription <text> - Set the chat description.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        if message.command == 'settitle' then
            return api.send_message(message.chat.id, 'Usage: /settitle <new title>')
        else
            return api.send_message(message.chat.id, 'Usage: /setdescription <new description>')
        end
    end

    if message.command == 'settitle' then
        local result = api.set_chat_title(message.chat.id, message.args)
        if result then
            return api.send_message(message.chat.id, 'Chat title updated.')
        end
        return api.send_message(message.chat.id, 'Failed to update chat title. Make sure I have the correct permissions.')
    else
        local result = api.set_chat_description(message.chat.id, message.args)
        if result then
            return api.send_message(message.chat.id, 'Chat description updated.')
        end
        return api.send_message(message.chat.id, 'Failed to update chat description. Make sure I have the correct permissions.')
    end
end

return plugin
