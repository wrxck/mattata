--[[
    mattata v2.0 - Topic Plugin
    Forum topic management for supergroups with topics enabled.
]]

local plugin = {}
plugin.name = 'topic'
plugin.category = 'admin'
plugin.description = 'Manage forum topics in supergroups'
plugin.commands = { 'topic' }
plugin.help = '/topic <create <name>|close|reopen|delete> - Manage forum topics.'
plugin.group_only = true
plugin.admin_only = true

local tools = require('telegram-bot-lua.tools')

function plugin.on_message(api, message, ctx)
    if not message.args then
        return api.send_message(message.chat.id,
            '<b>Topic management</b>\n\n'
            .. '<code>/topic create &lt;name&gt;</code> - Create a new topic\n'
            .. '<code>/topic close</code> - Close the current topic\n'
            .. '<code>/topic reopen</code> - Reopen a closed topic\n'
            .. '<code>/topic delete</code> - Delete the current topic\n\n'
            .. 'Close, reopen, and delete must be used inside a topic thread.',
            { parse_mode = 'html' }
        )
    end

    local action, rest = message.args:match('^(%S+)%s*(.*)')
    if not action then
        return api.send_message(message.chat.id, 'Usage: /topic <create <name>|close|reopen|delete>')
    end

    action = action:lower()

    if action == 'create' then
        local name = rest and rest:match('^%s*(.+)%s*$')
        if not name or name == '' then
            return api.send_message(message.chat.id, 'Usage: /topic create <name>')
        end

        local result = api.create_forum_topic(message.chat.id, name)
        if not result or not result.result then
            return api.send_message(message.chat.id,
                'I couldn\'t create the topic. Make sure the group has topics enabled and I have the right permissions.'
            )
        end

        pcall(function()
            ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, nil, 'topic', 'Created topic: ' .. name))
        end)

        return api.send_message(message.chat.id,
            string.format('Topic <b>%s</b> has been created.', tools.escape_html(name)),
            { parse_mode = 'html' }
        )

    elseif action == 'close' then
        if not message.is_topic or not message.thread_id then
            return api.send_message(message.chat.id, 'This command must be used inside a topic thread.')
        end

        local result = api.close_forum_topic(message.chat.id, message.thread_id)
        if not result or not result.result then
            return api.send_message(message.chat.id,
                'I couldn\'t close this topic. Make sure I have the right permissions.'
            )
        end

        pcall(function()
            ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, nil, 'topic', 'Closed topic ' .. message.thread_id))
        end)

        return api.send_message(message.chat.id, 'This topic has been closed.')

    elseif action == 'reopen' then
        if not message.is_topic or not message.thread_id then
            return api.send_message(message.chat.id, 'This command must be used inside a topic thread.')
        end

        local result = api.reopen_forum_topic(message.chat.id, message.thread_id)
        if not result or not result.result then
            return api.send_message(message.chat.id,
                'I couldn\'t reopen this topic. Make sure I have the right permissions.'
            )
        end

        pcall(function()
            ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, nil, 'topic', 'Reopened topic ' .. message.thread_id))
        end)

        return api.send_message(message.chat.id, 'This topic has been reopened.')

    elseif action == 'delete' then
        if not message.is_topic or not message.thread_id then
            return api.send_message(message.chat.id, 'This command must be used inside a topic thread.')
        end

        local result = api.delete_forum_topic(message.chat.id, message.thread_id)
        if not result or not result.result then
            return api.send_message(message.chat.id,
                'I couldn\'t delete this topic. Make sure I have the right permissions.'
            )
        end

        pcall(function()
            ctx.db.call('sp_log_admin_action', table.pack(message.chat.id, message.from.id, nil, 'topic', 'Deleted topic ' .. message.thread_id))
        end)

    else
        return api.send_message(message.chat.id, 'Unknown action. Usage: /topic <create <name>|close|reopen|delete>')
    end
end

return plugin
