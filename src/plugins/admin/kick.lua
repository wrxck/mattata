--[[
    mattata v2.0 - Kick Plugin
]]

local plugin = {}
plugin.name = 'kick'
plugin.category = 'admin'
plugin.description = 'Kick users from a group'
plugin.commands = { 'kick' }
plugin.help = '/kick [user] [reason] - Kicks a user from the current chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to use this command.')
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
        return api.send_message(message.chat.id, 'Please specify the user to kick.')
    end
    if tonumber(user_id) == nil then
        local name = user_id:match('^@?(.+)$')
        user_id = ctx.redis.get('username:' .. name:lower())
    end
    user_id = tonumber(user_id)
    if not user_id or user_id == api.info.id then return end
    if permissions.is_group_admin(api, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'I can\'t kick an admin or moderator.')
    end
    -- Kick = ban + immediate unban
    local success = api.ban_chat_member(message.chat.id, user_id)
    if not success then
        return api.send_message(message.chat.id, 'I don\'t have permission to kick users.')
    end
    api.unban_chat_member(message.chat.id, user_id)

    pcall(function()
        ctx.db.insert('admin_actions', {
            chat_id = message.chat.id, admin_id = message.from.id,
            target_id = user_id, action = 'kick', reason = reason
        })
    end)

    if reason and reason:lower():match('^for ') then reason = reason:sub(5) end
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    local reason_text = reason and ('\nReason: ' .. tools.escape_html(reason)) or ''
    api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has kicked <a href="tg://user?id=%d">%s</a>.%s',
        message.from.id, admin_name, user_id, target_name, reason_text
    ), 'html')
    if message.reply then
        pcall(function() api.delete_message(message.chat.id, message.reply.message_id) end)
    end
    pcall(function() api.delete_message(message.chat.id, message.message_id) end)
end

return plugin
