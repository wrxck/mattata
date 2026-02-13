--[[
    mattata v2.0 - Federation: feds / fedinfo

    Shows info about a specific federation by ID, or the federation
    the current chat belongs to.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'feds'
plugin.category = 'admin'
plugin.description = 'Show federation info.'
plugin.commands = { 'feds', 'fedinfo' }
plugin.help = '/feds [federation_id] - Show info about a federation.\n/fedinfo [federation_id] - Alias for /feds.'
plugin.group_only = false
plugin.admin_only = false

local function get_chat_federation(db, chat_id)
    local result = db.call('sp_get_chat_federation', { chat_id })
    if result and #result > 0 then return result[1] end
    return nil
end

function plugin.on_message(api, message, ctx)
    local fed_id = message.args and message.args:match('^(%S+)')
    local fed

    if fed_id and fed_id ~= '' then
        local result = ctx.db.call('sp_get_federation', { fed_id })
        if not result or #result == 0 then
            return api.send_message(
                message.chat.id,
                'Federation not found. Please check the ID and try again.',
                { parse_mode = 'html' }
            )
        end
        fed = result[1]
    elseif ctx.is_group then
        fed = get_chat_federation(ctx.db, message.chat.id)
        if not fed then
            return api.send_message(
                message.chat.id,
                'This chat is not part of any federation. Provide a federation ID to look up.\nUsage: <code>/feds &lt;federation_id&gt;</code>',
                { parse_mode = 'html' }
            )
        end
        local full = ctx.db.call('sp_get_federation', { fed.id })
        if full and #full > 0 then
            fed.created_at = full[1].created_at
        end
    else
        return api.send_message(
            message.chat.id,
            'Please specify a federation ID.\nUsage: <code>/feds &lt;federation_id&gt;</code>',
            { parse_mode = 'html' }
        )
    end

    local counts = ctx.db.call('sp_get_federation_counts', { fed.id })
    local counts_row = (counts and counts[1]) or {}
    local admins = tonumber(counts_row.admin_count) or 0
    local chats = tonumber(counts_row.chat_count) or 0
    local bans = tonumber(counts_row.ban_count) or 0

    local output = string.format(
        '<b>Federation Info</b>\n\nName: <b>%s</b>\nID: <code>%s</code>\nOwner: <code>%s</code>\nAdmins: %d\nChats: %d\nBans: %d',
        tools.escape_html(fed.name),
        tools.escape_html(fed.id),
        fed.owner_id,
        admins,
        chats,
        bans
    )

    if fed.created_at then
        output = output .. string.format('\nCreated: %s', tools.escape_html(tostring(fed.created_at)))
    end

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
