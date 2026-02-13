--[[
    mattata v2.1 - Unpin All Plugin
    Unpins all messages in a chat.
]]

local plugin = {}
plugin.name = 'unpinall'
plugin.category = 'admin'
plugin.description = 'Unpin all pinned messages'
plugin.commands = { 'unpinall' }
plugin.help = '/unpinall - Unpins all pinned messages in this chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local permissions = require('src.core.permissions')
    if not permissions.can_pin(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Pin Messages" admin permission to use this command.')
    end

    local result = api.unpin_all_chat_messages(message.chat.id)
    if result then
        return api.send_message(message.chat.id, 'All pinned messages have been unpinned.')
    end
    return api.send_message(message.chat.id, 'Failed to unpin messages. Make sure I have the correct permissions.')
end

return plugin
