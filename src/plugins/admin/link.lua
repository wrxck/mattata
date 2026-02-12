--[[
    mattata v2.0 - Link Plugin
]]

local plugin = {}
plugin.name = 'link'
plugin.category = 'admin'
plugin.description = 'Get or set the group invite link'
plugin.commands = { 'link' }
plugin.help = '/link - Gets the group invite link. Admins can use /link set to generate a new one.'
plugin.group_only = true
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local permissions = require('src.core.permissions')

    if message.args and message.args:lower() == 'set' then
        -- Only admins can set the link
        if not ctx.is_admin and not ctx.is_global_admin then
            return api.send_message(message.chat.id, 'Only admins can generate a new invite link.')
        end

        local result = api.export_chat_invite_link(message.chat.id)
        if not result or not result.result then
            return api.send_message(message.chat.id, 'I couldn\'t generate an invite link. Make sure I have the right permissions.')
        end

        ctx.db.upsert('chat_settings', {
            chat_id = message.chat.id,
            key = 'invite_link',
            value = result.result
        }, { 'chat_id', 'key' }, { 'value' })

        return api.send_message(message.chat.id, 'Invite link updated: ' .. result.result)
    end

    -- Try to get stored link first
    local stored = ctx.db.execute(
        "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'invite_link'",
        { message.chat.id }
    )
    if stored and #stored > 0 and stored[1].value then
        return api.send_message(message.chat.id, stored[1].value)
    end

    -- Try to get chat info which may contain invite link
    local chat = api.get_chat(message.chat.id)
    if chat and chat.result and chat.result.invite_link then
        return api.send_message(message.chat.id, chat.result.invite_link)
    end

    -- Try to export one if we're admin
    if permissions.is_group_admin(api, message.chat.id, api.info.id) then
        local result = api.export_chat_invite_link(message.chat.id)
        if result and result.result then
            ctx.db.upsert('chat_settings', {
                chat_id = message.chat.id,
                key = 'invite_link',
                value = result.result
            }, { 'chat_id', 'key' }, { 'value' })
            return api.send_message(message.chat.id, result.result)
        end
    end

    api.send_message(message.chat.id, 'No invite link is available. An admin can use /link set to generate one.')
end

return plugin
