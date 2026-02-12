--[[
    mattata v2.0 - Federation: fadmins

    Lists all admins of the federation the current chat belongs to.
    Shows the owner separately from promoted admins.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'fadmins'
plugin.category = 'admin'
plugin.description = 'List federation admins.'
plugin.commands = { 'fadmins' }
plugin.help = '/fadmins - List all admins of this federation.'
plugin.group_only = true
plugin.admin_only = false

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

    local output = string.format(
        '<b>Federation Admins</b>\nFederation: <b>%s</b>\n\n<b>Owner:</b>\n<code>%s</code>',
        tools.escape_html(fed.name),
        fed.owner_id
    )

    local admins = ctx.db.call('sp_get_federation_admins', { fed.id })

    if admins and #admins > 0 then
        output = output .. string.format('\n\n<b>Admins (%d):</b>', #admins)
        for i, admin in ipairs(admins) do
            output = output .. string.format('\n%d. <code>%s</code>', i, admin.user_id)
        end
    else
        output = output .. '\n\nNo promoted admins.'
    end

    return api.send_message(message.chat.id, output, 'html')
end

return plugin
