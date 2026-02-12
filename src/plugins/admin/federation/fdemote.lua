--[[
    mattata v2.0 - Federation: fdemote

    Demotes a federation admin. Only the federation owner can demote.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'fdemote'
plugin.category = 'admin'
plugin.description = 'Demote a federation admin.'
plugin.commands = { 'fdemote' }
plugin.help = '/fdemote [user] - Demote a federation admin.'
plugin.group_only = true
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

local function get_chat_federation(db, chat_id)
    local result = db.call('sp_get_chat_federation', { chat_id })
    if result and #result > 0 then return result[1] end
    return nil
end

function plugin.on_message(api, message, ctx)
    local fed = get_chat_federation(ctx.db, message.chat.id)
    if not fed then
        return api.send_message(
            message.chat.id,
            'This chat is not part of any federation.',
            'html'
        )
    end

    if fed.owner_id ~= message.from.id then
        return api.send_message(
            message.chat.id,
            'Only the federation owner can demote admins.',
            'html'
        )
    end

    local target_id, target_name = resolve_user(message, ctx)
    if not target_id then
        return api.send_message(
            message.chat.id,
            'Please specify a user to demote by replying to their message or providing a user ID/username.\nUsage: <code>/fdemote [user]</code>',
            'html'
        )
    end

    local existing = ctx.db.call('sp_check_federation_admin', { fed.id, target_id })
    if not existing or #existing == 0 then
        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> is not a federation admin.',
                tools.escape_html(target_name)
            ),
            'html'
        )
    end

    ctx.db.call('sp_delete_federation_admin', { fed.id, target_id })

    return api.send_message(
        message.chat.id,
        string.format(
            '<b>%s</b> has been demoted from federation admin in <b>%s</b>.',
            tools.escape_html(target_name),
            tools.escape_html(fed.name)
        ),
        'html'
    )
end

return plugin
