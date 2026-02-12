--[[
    mattata v2.0 - Federation: leavefed

    Removes the current chat from its federation. Requires group admin.
]]

local tools = require('telegram-bot-lua.tools')

local plugin = {}
plugin.name = 'leavefed'
plugin.category = 'admin'
plugin.description = 'Remove this chat from its federation.'
plugin.commands = { 'leavefed' }
plugin.help = '/leavefed - Remove this chat from its current federation.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local chat_id = message.chat.id

    local existing = ctx.db.call('sp_get_chat_federation_joined', { chat_id })
    if not existing or #existing == 0 then
        return api.send_message(
            chat_id,
            'This chat is not part of any federation.',
            'html'
        )
    end

    local fed = existing[1]

    ctx.db.call('sp_leave_federation', { fed.id, chat_id })

    return api.send_message(
        chat_id,
        string.format(
            'This chat has left the federation <b>%s</b>.',
            tools.escape_html(fed.name)
        ),
        'html'
    )
end

return plugin
