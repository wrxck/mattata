--[[
    mattata v2.0 - Command Stats Plugin
    Displays command usage statistics for the current chat.
]]

local plugin = {}
plugin.name = 'commandstats'
plugin.category = 'utility'
plugin.description = 'View command usage statistics for this chat'
plugin.commands = { 'commandstats', 'cstats' }
plugin.help = '/commandstats - View top 10 most used commands in this chat.\n/cstats reset - Reset command statistics (admin only).'
plugin.group_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local input = message.args

    -- Handle reset
    if input and input:lower() == 'reset' then
        if not ctx.is_admin and not ctx.is_global_admin then
            return api.send_message(message.chat.id, 'You need to be an admin to reset command statistics.')
        end
        ctx.db.call('sp_reset_command_stats', { message.chat.id })
        return api.send_message(message.chat.id, 'Command statistics have been reset for this chat.')
    end

    -- Query top 10 commands by usage
    local result = ctx.db.call('sp_get_top_commands', { message.chat.id })

    if not result or #result == 0 then
        return api.send_message(message.chat.id, 'No command statistics available for this chat yet.')
    end

    local lines = { '<b>Command Usage Statistics</b>', '' }
    local total_usage = 0
    for i, row in ipairs(result) do
        local count = tonumber(row.total) or 0
        total_usage = total_usage + count
        table.insert(lines, string.format(
            '%d. /%s - <code>%d</code> uses',
            i, tools.escape_html(row.command), count
        ))
    end

    table.insert(lines, '')
    table.insert(lines, string.format('<i>Total (top 10): %d command uses</i>', total_usage))

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
