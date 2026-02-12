--[[
    mattata v2.0 - Federation: myfeds

    Lists all federations the user owns or is admin of.
    Shows federation name, ID, chat count, and ban count.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'myfeds'
plugin.category = 'admin'
plugin.description = 'List your federations.'
plugin.commands = { 'myfeds' }
plugin.help = '/myfeds - List all federations you own or are an admin of.'
plugin.group_only = false
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local user_id = message.from.id

    -- Federations owned by the user
    local owned = ctx.db.execute(
        [[SELECT f.id, f.name,
            (SELECT COUNT(*) FROM federation_chats WHERE federation_id = f.id) AS chat_count,
            (SELECT COUNT(*) FROM federation_bans WHERE federation_id = f.id) AS ban_count
          FROM federations f
          WHERE f.owner_id = $1
          ORDER BY f.created_at ASC]],
        { user_id }
    )

    -- Federations where user is an admin (but not owner)
    local admin_of = ctx.db.execute(
        [[SELECT f.id, f.name, f.owner_id,
            (SELECT COUNT(*) FROM federation_chats WHERE federation_id = f.id) AS chat_count,
            (SELECT COUNT(*) FROM federation_bans WHERE federation_id = f.id) AS ban_count
          FROM federations f
          JOIN federation_admins fa ON f.id = fa.federation_id
          WHERE fa.user_id = $1 AND f.owner_id != $1
          ORDER BY fa.promoted_at ASC]],
        { user_id }
    )

    local has_owned = owned and #owned > 0
    local has_admin = admin_of and #admin_of > 0

    if not has_owned and not has_admin then
        return api.send_message(
            message.chat.id,
            'You do not own or administrate any federations.',
            'html'
        )
    end

    local output = '<b>Your Federations</b>\n'

    if has_owned then
        output = output .. string.format('\n<b>Owned (%d):</b>', #owned)
        for i, fed in ipairs(owned) do
            output = output .. string.format(
                '\n%d. <b>%s</b>\n    ID: <code>%s</code>\n    Chats: %d | Bans: %d',
                i,
                tools.escape_html(fed.name),
                tools.escape_html(fed.id),
                tonumber(fed.chat_count) or 0,
                tonumber(fed.ban_count) or 0
            )
        end
    end

    if has_admin then
        output = output .. string.format('\n\n<b>Admin of (%d):</b>', #admin_of)
        for i, fed in ipairs(admin_of) do
            output = output .. string.format(
                '\n%d. <b>%s</b>\n    ID: <code>%s</code>\n    Chats: %d | Bans: %d',
                i,
                tools.escape_html(fed.name),
                tools.escape_html(fed.id),
                tonumber(fed.chat_count) or 0,
                tonumber(fed.ban_count) or 0
            )
        end
    end

    return api.send_message(message.chat.id, output, 'html')
end

return plugin
