--[[
    mattata v2.0 - Purge Plugin
]]

local plugin = {}
plugin.name = 'purge'
plugin.category = 'admin'
plugin.description = 'Delete messages in bulk'
plugin.commands = { 'purge' }
plugin.help = '/purge - Deletes all messages from the replied-to message up to the command message.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local permissions = require('src.core.permissions')
    if not permissions.can_delete(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Delete Messages" admin permission to use this command.')
    end

    if not message.reply then
        return api.send_message(message.chat.id, 'Please reply to the first message you want to delete, and all messages from that point to your command will be purged.')
    end

    local start_id = message.reply.message_id
    local end_id = message.message_id
    local count = 0
    local failed = 0

    for msg_id = start_id, end_id do
        local success = api.delete_message(message.chat.id, msg_id)
        if success then
            count = count + 1
        else
            failed = failed + 1
        end
    end

    pcall(function()
        ctx.db.call('sp_log_admin_action', { message.chat.id, message.from.id, nil, 'purge', string.format('Purged %d messages (%d failed)', count, failed) })
    end)

    local status = api.send_message(message.chat.id, string.format('Purged <b>%d</b> message(s).', count), 'html')
    -- auto-delete the status message after a short delay
    if status and status.result then
        pcall(function()
            local socket = require('socket')
            socket.sleep(3)
            api.delete_message(message.chat.id, status.result.message_id)
        end)
    end
end

return plugin
