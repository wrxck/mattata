--[[
    mattata v2.0 - Pin Plugin
]]

local plugin = {}
plugin.name = 'pin'
plugin.category = 'admin'
plugin.description = 'Pin and unpin messages'
plugin.commands = { 'pin', 'unpin' }
plugin.help = '/pin - Pins the replied-to message. /unpin - Unpins the current pinned message.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local permissions = require('src.core.permissions')
    if not permissions.can_pin(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Pin Messages" admin permission to use this command.')
    end

    if message.command == 'pin' then
        if not message.reply then
            return api.send_message(message.chat.id, 'Please reply to the message you want to pin.')
        end

        -- Check for silent pin flag
        local disable_notification = true
        if message.args and (message.args:lower() == 'loud' or message.args:lower() == 'notify') then
            disable_notification = false
        end

        local success = api.pin_chat_message(message.chat.id, message.reply.message_id, disable_notification)
        if not success then
            return api.send_message(message.chat.id, 'I couldn\'t pin that message. Make sure I have the right permissions.')
        end

        pcall(function()
            ctx.db.insert('admin_actions', {
                chat_id = message.chat.id,
                admin_id = message.from.id,
                action = 'pin',
                reason = 'Pinned message ' .. message.reply.message_id
            })
        end)

        -- Delete the command message
        pcall(function() api.delete_message(message.chat.id, message.message_id) end)

    elseif message.command == 'unpin' then
        local success
        if message.reply then
            success = api.unpin_chat_message(message.chat.id, message.reply.message_id)
        else
            success = api.unpin_chat_message(message.chat.id)
        end

        if not success then
            return api.send_message(message.chat.id, 'I couldn\'t unpin the message. Make sure I have the right permissions.')
        end

        pcall(function()
            ctx.db.insert('admin_actions', {
                chat_id = message.chat.id,
                admin_id = message.from.id,
                action = 'unpin'
            })
        end)

        api.send_message(message.chat.id, 'Message unpinned.')
    end
end

return plugin
