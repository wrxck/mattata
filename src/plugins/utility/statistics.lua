--[[
    mattata v2.0 - Statistics Plugin
    Displays message statistics for the current chat.
]]

local plugin = {}
plugin.name = 'statistics'
plugin.category = 'utility'
plugin.description = 'View message statistics for this chat'
plugin.commands = { 'statistics', 'stats', 'morestats' }
plugin.help = '/stats - View top 10 most active users in this chat.\n/morestats - View extended stats.\n/stats reset - Reset statistics (admin only).'
plugin.group_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local input = message.args

    -- Handle reset
    if input and input:lower() == 'reset' then
        if not ctx.is_admin and not ctx.is_global_admin then
            return api.send_message(message.chat.id, 'You need to be an admin to reset statistics.')
        end
        ctx.db.execute(
            'DELETE FROM message_stats WHERE chat_id = $1',
            { message.chat.id }
        )
        return api.send_message(message.chat.id, 'Message statistics have been reset for this chat.')
    end

    -- Query top 10 users by message count
    local result = ctx.db.execute(
        [[SELECT ms.user_id, SUM(ms.message_count) AS total,
                 u.first_name, u.last_name, u.username
          FROM message_stats ms
          LEFT JOIN users u ON ms.user_id = u.user_id
          WHERE ms.chat_id = $1
          GROUP BY ms.user_id, u.first_name, u.last_name, u.username
          ORDER BY total DESC
          LIMIT 10]],
        { message.chat.id }
    )

    if not result or #result == 0 then
        return api.send_message(message.chat.id, 'No message statistics available for this chat yet.')
    end

    local lines = { '<b>Message Statistics</b>', '' }
    local total_messages = 0
    for i, row in ipairs(result) do
        local name = tools.escape_html(row.first_name or 'Unknown')
        if row.last_name then
            name = name .. ' ' .. tools.escape_html(row.last_name)
        end
        local count = tonumber(row.total) or 0
        total_messages = total_messages + count
        table.insert(lines, string.format(
            '%d. %s - <code>%d</code> messages',
            i, name, count
        ))
    end

    table.insert(lines, '')
    table.insert(lines, string.format('<i>Total (top 10): %d messages</i>', total_messages))

    -- Extended stats for /morestats
    if message.command == 'morestats' then
        local total_result = ctx.db.execute(
            'SELECT SUM(message_count) AS total FROM message_stats WHERE chat_id = $1',
            { message.chat.id }
        )
        local unique_result = ctx.db.execute(
            'SELECT COUNT(DISTINCT user_id) AS total FROM message_stats WHERE chat_id = $1',
            { message.chat.id }
        )
        if total_result and total_result[1] then
            table.insert(lines, string.format(
                '<i>All-time total: %s messages</i>',
                total_result[1].total or '0'
            ))
        end
        if unique_result and unique_result[1] then
            table.insert(lines, string.format(
                '<i>Unique users: %s</i>',
                unique_result[1].total or '0'
            ))
        end
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
