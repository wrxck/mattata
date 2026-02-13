--[[
    mattata v2.0 - Federation: fallowlist

    Manages the federation allowlist. Allowlisted users are exempt from
    federation bans. Only the federation owner or admins can manage it.
    Toggles the user on/off the allowlist.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'fallowlist'
plugin.category = 'admin'
plugin.description = 'Toggle a user on the federation allowlist.'
plugin.commands = { 'fallowlist' }
plugin.help = '/fallowlist [user] - Toggle a user on/off the federation allowlist.'
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

local function is_fed_admin(db, fed_id, user_id)
    local result = db.call('sp_check_federation_admin', { fed_id, user_id })
    return result and #result > 0
end

function plugin.on_message(api, message, ctx)
    local fed = get_chat_federation(ctx.db, message.chat.id)
    if not fed then
        return api.send_message(
            message.chat.id,
            'This chat is not part of any federation.',
            { parse_mode = 'html' }
        )
    end

    local from_id = message.from.id
    if fed.owner_id ~= from_id and not is_fed_admin(ctx.db, fed.id, from_id) then
        return api.send_message(
            message.chat.id,
            'Only the federation owner or a federation admin can manage the allowlist.',
            { parse_mode = 'html' }
        )
    end

    local target_id, target_name = resolve_user(message, ctx)
    if not target_id then
        return api.send_message(
            message.chat.id,
            'Please specify a user to toggle on the allowlist by replying to their message or providing a user ID/username.\nUsage: <code>/fallowlist [user]</code>',
            { parse_mode = 'html' }
        )
    end

    local existing = ctx.db.call('sp_check_federation_allowlist', { fed.id, target_id })

    if existing and #existing > 0 then
        ctx.db.call('sp_delete_federation_allowlist', { fed.id, target_id })
        ctx.redis.del(string.format('fallowlist:%s:%s', fed.id, target_id))

        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> has been removed from the federation allowlist.',
                tools.escape_html(target_name)
            ),
            { parse_mode = 'html' }
        )
    else
        ctx.db.call('sp_insert_federation_allowlist', { fed.id, target_id })
        ctx.redis.del(string.format('fallowlist:%s:%s', fed.id, target_id))

        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> has been added to the federation allowlist.',
                tools.escape_html(target_name)
            ),
            { parse_mode = 'html' }
        )
    end
end

return plugin
