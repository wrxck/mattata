--[[
    mattata v2.0 - Tempmute Plugin
]]

local plugin = {}
plugin.name = 'tempmute'
plugin.category = 'admin'
plugin.description = 'Temporarily mute users'
plugin.commands = { 'tempmute', 'tmute' }
plugin.help = '/tempmute [user] <duration> - Temporarily mutes a user. Duration format: 1h, 2d.'
plugin.group_only = true
plugin.admin_only = true

local function parse_duration(str)
    if not str then return nil end
    local total = 0
    for num, unit in str:gmatch('(%d+)(%a)') do
        num = tonumber(num)
        if unit == 's' then total = total + num
        elseif unit == 'm' then total = total + num * 60
        elseif unit == 'h' then total = total + num * 3600
        elseif unit == 'd' then total = total + num * 86400
        elseif unit == 'w' then total = total + num * 604800
        end
    end
    return total > 0 and total or nil
end

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Restrict Members" admin permission to use this command.')
    end

    local user_id, duration_str
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
        duration_str = message.args
    elseif message.args then
        user_id, duration_str = message.args:match('^(%S+)%s+(.+)$')
        if not user_id then user_id = message.args end
    end
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user and duration.')
    end
    if tonumber(user_id) == nil then
        local name = user_id:match('^@?(.+)$')
        user_id = ctx.redis.get('username:' .. name:lower())
    end
    user_id = tonumber(user_id)
    if not user_id or user_id == api.info.id then return end

    local duration = parse_duration(duration_str)
    if not duration or duration < 60 then
        return api.send_message(message.chat.id, 'Please provide a valid duration (min 1 minute).')
    end
    if permissions.is_group_admin(api, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'I can\'t mute an admin.')
    end

    local until_date = os.time() + duration
    local perms = { can_send_messages = false }
    local success = api.restrict_chat_member(message.chat.id, user_id, perms, until_date)
    if not success then
        return api.send_message(message.chat.id, 'I don\'t have permission to mute users.')
    end
    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)
    return api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has temporarily muted <a href="tg://user?id=%d">%s</a> for %s.',
        message.from.id, admin_name, user_id, target_name, duration_str or 'unknown'
    ), 'html')
end

return plugin
