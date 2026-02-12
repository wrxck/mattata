--[[
    mattata v2.0 - Triggers Plugin
]]

local plugin = {}
plugin.name = 'triggers'
plugin.category = 'admin'
plugin.description = 'List all triggers in the group'
plugin.commands = { 'triggers' }
plugin.help = '/triggers - Lists all triggers set for this group.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    local triggers = ctx.db.call('sp_get_triggers_full', { message.chat.id })

    if not triggers or #triggers == 0 then
        return api.send_message(message.chat.id, 'No triggers are set. Use /addtrigger <pattern> <response> to add one.')
    end

    local output = '<b>Triggers for this group:</b>\n\n'
    for i, t in ipairs(triggers) do
        output = output .. string.format(
            '%d. <code>%s</code> -> %s\n',
            i,
            tools.escape_html(t.pattern),
            tools.escape_html(t.response:sub(1, 50)) .. (#t.response > 50 and '...' or '')
        )
    end
    output = output .. string.format('\n<i>Total: %d trigger(s)</i>', #triggers)

    api.send_message(message.chat.id, output, 'html')
end

return plugin
