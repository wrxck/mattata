--[[
    mattata v2.0 - Ban Plugin
]]

local plugin = {}
plugin.name = 'ban'
plugin.category = 'admin'
plugin.description = 'Ban users from a group'
plugin.commands = { 'ban', 'b' }
plugin.help = '/ban [user] [reason] - Bans a user from the current chat.'
plugin.group_only = true
plugin.admin_only = true

local function resolve_target(api, message, ctx)
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
    if not user_id then return nil, nil end
    -- strip 'for' prefix from reason
    if reason and reason:lower():match('^for ') then
        reason = reason:sub(5)
    end
    -- resolve username to id
    if tonumber(user_id) == nil then
        user_id = user_id:match('^@?(.+)$')
        user_id = ctx.redis.get('username:' .. user_id:lower())
    end
    return tonumber(user_id), reason
end

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to use this command.')
    end

    local user_id, reason = resolve_target(api, message, ctx)
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to ban, either by replying to their message or providing a username/ID.')
    end
    if user_id == api.info.id then return end

    -- check target isn't an admin
    if permissions.is_group_admin(api, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'I can\'t ban an admin or moderator.')
    end

    -- attempt ban
    local success = api.ban_chat_member(message.chat.id, user_id)
    if not success then
        return api.send_message(message.chat.id, 'I don\'t have permission to ban users. Please make sure I\'m an admin with ban rights.')
    end

    -- log to database
    pcall(function()
        ctx.db.call('sp_insert_ban', { message.chat.id, user_id, message.from.id, reason })
        ctx.db.call('sp_log_admin_action', { message.chat.id, message.from.id, user_id, 'ban', reason })
    end)

    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    local reason_text = reason and ('\nReason: ' .. tools.escape_html(reason)) or ''

    local output = string.format(
        '<a href="tg://user?id=%d">%s</a> has banned <a href="tg://user?id=%d">%s</a>.%s',
        message.from.id, admin_name, user_id, target_name, reason_text
    )
    api.send_message(message.chat.id, output, 'html')

    -- clean up messages
    if message.reply then
        pcall(function() api.delete_message(message.chat.id, message.reply.message_id) end)
    end
    pcall(function() api.delete_message(message.chat.id, message.message_id) end)
end

return plugin
