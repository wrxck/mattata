--[[
    mattata v2.0 - Channel Plugin
]]

local plugin = {}
plugin.name = 'channel'
plugin.category = 'admin'
plugin.description = 'Connect a channel to the group'
plugin.commands = { 'channel' }
plugin.help = '/channel <channel_id|@channel|off> - Connects a channel to this group.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.args then
        local result = ctx.db.execute(
            "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'linked_channel'",
            { message.chat.id }
        )
        if result and #result > 0 and result[1].value then
            local channel_info = api.get_chat(tonumber(result[1].value))
            local channel_name = channel_info and channel_info.result and channel_info.result.title or result[1].value
            return api.send_message(message.chat.id, string.format(
                'This group is linked to channel: <b>%s</b> (<code>%s</code>)\nUse /channel off to disconnect.',
                require('telegram-bot-lua.tools').escape_html(channel_name), result[1].value
            ), 'html')
        end
        return api.send_message(message.chat.id, 'No channel is linked. Use /channel <channel_id|@channel> to link one.')
    end

    local arg = message.args:lower()
    if arg == 'off' or arg == 'disable' or arg == 'none' then
        ctx.db.execute(
            "DELETE FROM chat_settings WHERE chat_id = $1 AND key = 'linked_channel'",
            { message.chat.id }
        )
        return api.send_message(message.chat.id, 'Channel has been disconnected from this group.')
    end

    -- Resolve channel
    local channel_id = message.args
    if tonumber(channel_id) == nil then
        -- Try to resolve by username
        local chat_info = api.get_chat(channel_id)
        if not chat_info or not chat_info.result then
            return api.send_message(message.chat.id, 'I couldn\'t find that channel. Make sure I\'m an admin there.')
        end
        channel_id = tostring(chat_info.result.id)
    end

    ctx.db.upsert('chat_settings', {
        chat_id = message.chat.id,
        key = 'linked_channel',
        value = channel_id
    }, { 'chat_id', 'key' }, { 'value' })

    api.send_message(message.chat.id, string.format('Channel <code>%s</code> has been linked to this group.', channel_id), 'html')
end

return plugin
