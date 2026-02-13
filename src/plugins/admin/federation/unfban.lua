--[[
    mattata v2.0 - Federation: unfban

    Unbans a user from the federation and all its chats.
    Only the federation owner or a federation admin can unfban.
]]

local tools = require('telegram-bot-lua.tools')
local permissions = require('src.core.permissions')

local plugin = {}
plugin.name = 'unfban'
plugin.category = 'admin'
plugin.description = 'Unban a user from the federation.'
plugin.commands = { 'unfban' }
plugin.help = '/unfban [user] - Unban a user from all chats in this federation.'
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
    if message.chat.type ~= 'private' and not permissions.can_restrict(api, message.chat.id) then
        return api.send_message(message.chat.id, 'I need the "Ban Users" admin permission to enforce federation unbans.')
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
            'Please specify a user to unban by replying to their message or providing a user ID/username.\nUsage: <code>/unfban [user]</code>',
            { parse_mode = 'html' }
        )
    end

    local ban = ctx.db.call('sp_check_federation_ban_exists', { fed.id, target_id })
    if not ban or #ban == 0 then
        return api.send_message(
            message.chat.id,
            string.format(
                '<b>%s</b> (<code>%s</code>) is not banned in this federation.',
                tools.escape_html(target_name),
                target_id
            ),
            { parse_mode = 'html' }
        )
    end

    ctx.db.call('sp_delete_federation_ban', { fed.id, target_id })

    ctx.redis.del(string.format('fban:%s:%s', fed.id, target_id))

    local chats = ctx.db.call('sp_get_federation_chats', { fed.id })

    local success_count = 0
    local fail_count = 0
    if chats then
        for _, chat in ipairs(chats) do
            local ok = api.unban_chat_member(chat.chat_id, target_id)
            if ok then
                success_count = success_count + 1
            else
                fail_count = fail_count + 1
            end
        end
    end

    local output = string.format(
        '<b>Federation Unban</b>\nFederation: <b>%s</b>\nUser: <b>%s</b> (<code>%s</code>)\nUnbanned by: %s\nUnbanned in %d/%d chats.',
        tools.escape_html(fed.name),
        tools.escape_html(target_name),
        target_id,
        tools.escape_html(message.from.first_name),
        success_count,
        success_count + fail_count
    )

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
