--[[
    mattata v2.1 - Bulk Operations Plugin
    Forward or copy messages between chats.
]]

local plugin = {}
plugin.name = 'bulkops'
plugin.category = 'admin'
plugin.description = 'Forward or copy messages'
plugin.commands = { 'forward', 'copy' }
plugin.help = '/forward <chat_id> - Forward the replied message to another chat.\n/copy <chat_id> - Copy the replied message to another chat (without forward header).'
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.reply then
        return api.send_message(message.chat.id, 'Reply to a message with /' .. message.command .. ' <chat_id> to ' .. message.command .. ' it.')
    end

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Usage: /' .. message.command .. ' <chat_id>')
    end

    local target_chat = tonumber(message.args)
    if not target_chat then
        -- Try to resolve as username
        target_chat = message.args:match('^@?(.+)$')
    end

    if not target_chat then
        return api.send_message(message.chat.id, 'Invalid chat ID or username.')
    end

    local result
    if message.command == 'forward' then
        result = api.forward_messages(target_chat, message.chat.id, { message.reply.message_id })
    else
        result = api.copy_messages(target_chat, message.chat.id, { message.reply.message_id })
    end

    if result then
        return api.send_message(message.chat.id, 'Message ' .. message.command .. 'ed successfully.')
    end
    return api.send_message(message.chat.id, 'Failed to ' .. message.command .. ' the message. Make sure the bot has access to the target chat.')
end

return plugin
