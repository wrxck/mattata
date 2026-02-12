--[[
    mattata v2.0 - Unban Plugin
]]

local plugin = {}
plugin.name = 'unban'
plugin.category = 'admin'
plugin.description = 'Unban users from a group'
plugin.commands = { 'unban' }
plugin.help = '/unban [user] - Unbans a user from the current chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to use this command.')
    end

    local user_id
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
    elseif message.args and message.args ~= '' then
        local input = message.args:match('^@?(%S+)')
        user_id = tonumber(input) or ctx.redis.get('username:' .. input:lower())
    end
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to unban.')
    end
    user_id = tonumber(user_id)
    local success = api.unban_chat_member(message.chat.id, user_id)
    if not success then
        return api.send_message(message.chat.id, 'I couldn\'t unban that user.')
    end
    pcall(function()
        ctx.db.call('sp_log_admin_action', { message.chat.id, message.from.id, user_id, 'unban', nil })
    end)
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    return api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has unbanned <a href="tg://user?id=%d">%s</a>.',
        message.from.id, admin_name, user_id, target_name
    ), 'html')
end

return plugin
