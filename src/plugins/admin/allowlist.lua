--[[
    mattata v2.0 - Allowlist Plugin
]]

local plugin = {}
plugin.name = 'allowlist'
plugin.category = 'admin'
plugin.description = 'Manage the group allowlist'
plugin.commands = { 'allowlist' }
plugin.help = '/allowlist add <user> - Adds a user to the allowlist. /allowlist remove <user> - Removes a user. /allowlist - Lists allowlisted users.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        -- list allowlisted users
        local result = ctx.db.call('sp_get_allowlisted_users', { message.chat.id })
        if not result or #result == 0 then
            return api.send_message(message.chat.id, 'No users are allowlisted.\nUsage: /allowlist add <user>')
        end
        local output = '<b>Allowlisted users:</b>\n\n'
        for _, row in ipairs(result) do
            local info = api.get_chat(row.user_id)
            local name = info and info.result and tools.escape_html(info.result.first_name) or tostring(row.user_id)
            output = output .. string.format('- <a href="tg://user?id=%s">%s</a> [%s]\n', row.user_id, name, row.user_id)
        end
        return api.send_message(message.chat.id, output, 'html')
    end

    local action, target = message.args:lower():match('^(%S+)%s+(.+)$')
    if not action then
        return api.send_message(message.chat.id, 'Usage: /allowlist <add|remove> <user>')
    end

    -- resolve target user
    local user_id
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
    else
        user_id = target:match('^@?(%S+)')
        if tonumber(user_id) == nil then
            user_id = ctx.redis.get('username:' .. user_id:lower())
        end
    end
    user_id = tonumber(user_id)
    if not user_id then
        return api.send_message(message.chat.id, 'I couldn\'t find that user. Try replying to their message or providing a valid username/ID.')
    end

    if action == 'add' then
        ctx.db.call('sp_set_member_role', { message.chat.id, user_id, 'allowlisted' })

        local target_info = api.get_chat(user_id)
        local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
        api.send_message(message.chat.id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been added to the allowlist.',
            user_id, target_name
        ), 'html')

    elseif action == 'remove' or action == 'del' or action == 'delete' then
        ctx.db.call('sp_remove_allowlisted', { message.chat.id, user_id })
        local target_info = api.get_chat(user_id)
        local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
        api.send_message(message.chat.id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been removed from the allowlist.',
            user_id, target_name
        ), 'html')

    else
        api.send_message(message.chat.id, 'Usage: /allowlist <add|remove> <user>')
    end
end

return plugin
