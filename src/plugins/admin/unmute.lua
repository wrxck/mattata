--[[
    mattata v2.0 - Unmute Plugin
]]

local plugin = {}
plugin.name = 'unmute'
plugin.category = 'admin'
plugin.description = 'Unmute users in a group'
plugin.commands = { 'unmute' }
plugin.help = '/unmute [user] - Unmutes a user in the current chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Restrict Members" admin permission to use this command.')
    end

    local user_id
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
    elseif message.args and message.args ~= '' then
        local input = message.args:match('^@?(%S+)')
        user_id = tonumber(input) or ctx.redis.get('username:' .. input:lower())
    end
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to unmute.')
    end
    user_id = tonumber(user_id)
    local perms = {
        can_send_messages = true,
        can_send_audios = true,
        can_send_documents = true,
        can_send_photos = true,
        can_send_videos = true,
        can_send_video_notes = true,
        can_send_voice_notes = true,
        can_send_polls = true,
        can_send_other_messages = true,
        can_add_web_page_previews = true,
        can_invite_users = true,
        can_change_info = false,
        can_pin_messages = false,
        can_manage_topics = false
    }
    local success = api.restrict_chat_member(message.chat.id, user_id, perms)
    if not success then
        return api.send_message(message.chat.id, 'I couldn\'t unmute that user.')
    end
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    return api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has unmuted <a href="tg://user?id=%d">%s</a>.',
        message.from.id, admin_name, user_id, target_name
    ), { parse_mode = 'html' })
end

return plugin
