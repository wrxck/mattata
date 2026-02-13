--[[
    mattata v2.0 - Mute Plugin
]]

local plugin = {}
plugin.name = 'mute'
plugin.category = 'admin'
plugin.description = 'Mute users in a group'
plugin.commands = { 'mute' }
plugin.help = '/mute [user] [reason] - Mutes a user in the current chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Restrict Members" admin permission to use this command.')
    end

    local user_id, reason
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
        reason = message.args
    elseif message.args then
        local input = message.args
        if input:match('^(%S+)%s+(.+)$') then
            user_id, reason = input:match('^(%S+)%s+(.+)$')
        else
            user_id = input
        end
    end
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to mute.')
    end
    if tonumber(user_id) == nil then
        local name = user_id:match('^@?(.+)$')
        user_id = ctx.redis.get('username:' .. name:lower())
    end
    user_id = tonumber(user_id)
    if not user_id or user_id == api.info.id then return end
    if permissions.is_group_admin(api, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'I can\'t mute an admin or moderator.')
    end

    local perms = {
        can_send_messages = false,
        can_send_audios = false,
        can_send_documents = false,
        can_send_photos = false,
        can_send_videos = false,
        can_send_video_notes = false,
        can_send_voice_notes = false,
        can_send_polls = false,
        can_send_other_messages = false,
        can_add_web_page_previews = false,
        can_invite_users = false,
        can_change_info = false,
        can_pin_messages = false,
        can_manage_topics = false
    }
    local success = api.restrict_chat_member(message.chat.id, user_id, perms)
    if not success then
        return api.send_message(message.chat.id, 'I don\'t have permission to mute users.')
    end

    pcall(function()
        ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, user_id, 'mute', reason))
    end)

    if reason and reason:lower():match('^for ') then reason = reason:sub(5) end
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    local reason_text = reason and (', for ' .. tools.escape_html(reason)) or ''
    return api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has muted <a href="tg://user?id=%d">%s</a>%s.',
        message.from.id, admin_name, user_id, target_name, reason_text
    ), { parse_mode = 'html' })
end

return plugin
