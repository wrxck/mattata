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
    local result = db.execute(
        'SELECT f.id, f.name, f.owner_id FROM federations f JOIN federation_chats fc ON f.id = fc.federation_id WHERE fc.chat_id = $1',
        { chat_id }
    )
    if result and #result > 0 then return result[1] end
    return nil
end

function plugin.on_message(api, message, ctx)
    local fed_id = message.args and message.args:match('^(%S+)')
    local fed

    if fed_id and fed_id ~= '' then
        local result = ctx.db.execute(
            'SELECT id, name, owner_id, created_at FROM federations WHERE id = $1',
            { fed_id }
        )
        if not result or #result == 0 then
            return api.send_message(
                message.chat.id,
                'Federation not found. Please check the ID and try again.',
                'html'
            )
        end
        fed = result[1]
    elseif ctx.is_group then
        fed = get_chat_federation(ctx.db, message.chat.id)
        if not fed then
            return api.send_message(
                message.chat.id,
                'This chat is not part of any federation. Provide a federation ID to look up.\nUsage: <code>/feds &lt;federation_id&gt;</code>',
                'html'
            )
        end
        -- Fetch created_at since get_chat_federation doesn't include it
        local full = ctx.db.execute(
            'SELECT created_at FROM federations WHERE id = $1',
            { fed.id }
        )
        if full and #full > 0 then
            fed.created_at = full[1].created_at
        end
    else
        return api.send_message(
            message.chat.id,
            'Please specify a federation ID.\nUsage: <code>/feds &lt;federation_id&gt;</code>',
            'html'
        )
    end

    -- Get counts
    local admin_count = ctx.db.execute(
        'SELECT COUNT(*) AS count FROM federation_admins WHERE federation_id = $1',
        { fed.id }
    )
    local chat_count = ctx.db.execute(
        'SELECT COUNT(*) AS count FROM federation_chats WHERE federation_id = $1',
        { fed.id }
    )
    local ban_count = ctx.db.execute(
        'SELECT COUNT(*) AS count FROM federation_bans WHERE federation_id = $1',
        { fed.id }
    )

    local admins = (admin_count and admin_count[1]) and tonumber(admin_count[1].count) or 0
    local chats = (chat_count and chat_count[1]) and tonumber(chat_count[1].count) or 0
    local bans = (ban_count and ban_count[1]) and tonumber(ban_count[1].count) or 0

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

    return api.send_message(message.chat.id, output, 'html')
end

return plugin
