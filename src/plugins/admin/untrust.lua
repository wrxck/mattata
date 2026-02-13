--[[
    mattata v2.0 - Untrust Plugin
]]

local plugin = {}
plugin.name = 'untrust'
plugin.category = 'admin'
plugin.description = 'Remove trusted status from a user'
plugin.commands = { 'untrust' }
plugin.help = '/untrust [user] - Removes trusted status from a user.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    local user_id
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
    elseif message.args then
        user_id = message.args:match('^@?(%S+)')
        if tonumber(user_id) == nil then
            user_id = ctx.redis.get('username:' .. user_id:lower())
        end
    end
    user_id = tonumber(user_id)
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to untrust, either by replying to their message or providing a username/ID.')
    end
    if not permissions.is_trusted(ctx.db, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'That user is not trusted.')
    end

    ctx.db.call('sp_reset_member_role', { message.chat.id, user_id })

    pcall(function()
        ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, user_id, 'untrust', nil))
    end)

    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)

    api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has removed trusted status from <a href="tg://user?id=%d">%s</a>.',
        message.from.id, admin_name, user_id, target_name
    ), { parse_mode = 'html' })
end

return plugin
