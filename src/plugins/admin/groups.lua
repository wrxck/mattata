--[[
    mattata v2.0 - Groups Plugin
]]

local plugin = {}
plugin.name = 'groups'
plugin.category = 'admin'
plugin.description = 'List known groups the bot is in'
plugin.commands = { 'groups' }
plugin.help = '/groups [search] - Lists groups the bot is aware of.'
plugin.group_only = false
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    local search = message.args and message.args:lower() or nil
    local result
    if search then
        result = ctx.db.call('sp_search_groups', { '%' .. search .. '%' })
    else
        result = ctx.db.call('sp_list_groups', {})
    end

    if not result or #result == 0 then
        if search then
            return api.send_message(message.chat.id, 'No groups found matching that search.')
        end
        return api.send_message(message.chat.id, 'No groups found in the database.')
    end

    local output = '<b>Known groups'
    if search then
        output = output .. ' matching "' .. tools.escape_html(search) .. '"'
    end
    output = output .. ':</b>\n\n'

    for i, row in ipairs(result) do
        local title = tools.escape_html(row.title or 'Unknown')
        if row.username then
            output = output .. string.format('%d. <a href="https://t.me/%s">%s</a>\n', i, row.username, title)
        else
            output = output .. string.format('%d. %s (<code>%s</code>)\n', i, title, row.chat_id)
        end
    end

    if #result == 50 then
        output = output .. '\n<i>Showing first 50 results. Use /groups <search> to narrow down.</i>'
    end

    api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
