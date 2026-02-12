--[[
    mattata v2.0 - Allowed Links Plugin
]]

local plugin = {}
plugin.name = 'allowedlinks'
plugin.category = 'admin'
plugin.description = 'List allowed links in the group'
plugin.commands = { 'allowedlinks' }
plugin.help = '/allowedlinks - Lists all links that are allowed in this group when anti-link is enabled.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    local result = ctx.db.execute(
        'SELECT link FROM allowed_links WHERE chat_id = $1 ORDER BY link',
        { message.chat.id }
    )

    if not result or #result == 0 then
        return api.send_message(message.chat.id, 'No links are allowlisted. Use /allowlink <link> to add one.')
    end

    local output = '<b>Allowed links:</b>\n\n'
    for i, row in ipairs(result) do
        output = output .. string.format('%d. <code>%s</code>\n', i, tools.escape_html(row.link))
    end
    output = output .. string.format('\n<i>Total: %d link(s)</i>\nUse /allowlink <link> to add more.', #result)

    api.send_message(message.chat.id, output, 'html')
end

return plugin
