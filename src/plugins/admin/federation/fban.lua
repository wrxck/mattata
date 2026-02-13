--[[
    mattata v2.0 - Federation: fban

    Bans a user across all chats in the federation.
    Only the federation owner or a federation admin can issue an fban.
    Allowlisted users are exempt.
]]

local tools = require('telegram-bot-lua.tools')
local permissions = require('src.core.permissions')

local plugin = {}
plugin.name = 'fban'
plugin.category = 'admin'
plugin.description = 'Ban a user across the federation.'
plugin.commands = { 'fban' }
plugin.help = '/fban [user] [reason] - Ban a user in all chats belonging to this federation.'
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

local function is_allowlisted(db, fed_id, user_id)
    local result = db.call('sp_check_federation_allowlist', { fed_id, user_id })
    return result and #result > 0
end

function plugin.on_message(api, message, ctx)
    if message.chat.type ~= 'private' and not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to enforce federation bans.')
    end

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
            'Only the federation owner or a federation admin can use this command.',
            { parse_mode = 'html' }
        )
    end

    local target_id, target_name = resolve_user(message, ctx)
    if not target_id then
        return api.send_message(
            message.chat.id,
            'Please specify a user to ban by replying to their message or providing a user ID/username.\nUsage: <code>/fban [user] [reason]</code>',
            { parse_mode = 'html' }
        )
    end

    -- don't allow banning the federation owner
    if target_id == fed.owner_id then
        return api.send_message(
            message.chat.id,
            'You cannot federation-ban the federation owner.',
            { parse_mode = 'html' }
        )
    end

    if is_allowlisted(ctx.db, fed.id, target_id) then
        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> is on the federation allowlist and cannot be banned.',
                tools.escape_html(target_name)
            ),
            { parse_mode = 'html' }
        )
    end

    local reason
    if message.reply and message.reply.from and message.args and message.args ~= '' then
        reason = message.args
    elseif message.args and message.args ~= '' then
        reason = message.args:match('^%S+%s+(.*)')
    end

    local existing_ban = ctx.db.call('sp_check_federation_ban_exists', { fed.id, target_id })
    if existing_ban and #existing_ban > 0 then
        if reason then
            ctx.db.call('sp_update_federation_ban', { reason, from_id, fed.id, target_id })
        end
    else
        ctx.db.call('sp_insert_federation_ban', { fed.id, target_id, reason, from_id })
    end

    ctx.redis.del(string.format('fban:%s:%s', fed.id, target_id))

    local chats = ctx.db.call('sp_get_federation_chats', { fed.id })

    local success_count = 0
    local fail_count = 0
    if chats then
        for _, chat in ipairs(chats) do
            local ok = api.ban_chat_member(chat.chat_id, target_id)
            if ok then
                success_count = success_count + 1
            else
                fail_count = fail_count + 1
            end
        end
    end

    local output = string.format(
        '<b>Federation Ban</b>\nFederation: <b>%s</b>\nUser: <b>%s</b> (<code>%s</code>)\nBanned by: %s',
        tools.escape_html(fed.name),
        tools.escape_html(target_name),
        target_id,
        tools.escape_html(message.from.first_name)
    )

    if reason then
        output = output .. string.format('\nReason: %s', tools.escape_html(reason))
    end

    output = output .. string.format('\nBanned in %d/%d chats.', success_count, success_count + fail_count)

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
