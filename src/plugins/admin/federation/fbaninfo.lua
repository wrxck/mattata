--[[
    mattata v2.0 - Federation: fbaninfo

    Checks if a user is banned in any federation the current chat belongs to.
    Shows the ban reason, who banned them, and when.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'fbaninfo'
plugin.category = 'admin'
plugin.description = 'Check federation ban info for a user.'
plugin.commands = { 'fbaninfo' }
plugin.help = '/fbaninfo [user] - Check if a user is banned in this federation.'
plugin.group_only = false
plugin.admin_only = false

local function resolve_user(message, ctx)
    if message.reply and message.reply.from then
        return message.reply.from.id, message.reply.from.first_name
    end
    if message.args and message.args ~= '' then
        local input = message.args:match('^(%S+)')
        if tonumber(input) then
            return tonumber(input), input
        end
        local username = input:gsub('^@', ''):lower()
        local user_id = ctx.redis.get('username:' .. username)
        if user_id then
            return tonumber(user_id), '@' .. username
        end
    end
    return nil, nil
end

function plugin.on_message(api, message, ctx)
    local target_id, target_name = resolve_user(message, ctx)
    if not target_id then
        target_id = message.from.id
        target_name = message.from.first_name
    end

    local bans
    if ctx.is_group then
        bans = ctx.db.call('sp_get_fban_info_group', { target_id, message.chat.id })
    else
        bans = ctx.db.call('sp_get_fban_info_all', { target_id })
    end

    if not bans or #bans == 0 then
        local scope = ctx.is_group and 'this federation' or 'any federation'
        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> (<code>%s</code>) is not banned in %s.',
                tools.escape_html(target_name),
                target_id,
                scope
            ),
            'html'
        )
    end

    local output = string.format(
        '<b>Federation Ban Info</b>\nUser: <b>%s</b> (<code>%s</code>)\n',
        tools.escape_html(target_name),
        target_id
    )

    for i, ban in ipairs(bans) do
        output = output .. string.format(
            '\n<b>%d.</b> Federation: <b>%s</b>\n    ID: <code>%s</code>',
            i,
            tools.escape_html(ban.name),
            tools.escape_html(ban.id)
        )
        if ban.reason then
            output = output .. string.format('\n    Reason: %s', tools.escape_html(ban.reason))
        end
        if ban.banned_by then
            output = output .. string.format('\n    Banned by: <code>%s</code>', ban.banned_by)
        end
        if ban.banned_at then
            output = output .. string.format('\n    Date: %s', tools.escape_html(tostring(ban.banned_at)))
        end
    end

    return api.send_message(message.chat.id, output, 'html')
end

return plugin
