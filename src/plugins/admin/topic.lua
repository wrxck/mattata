--[[
    mattata v2.1 - Topic Plugin
    Forum topic management for supergroups with topics enabled.
]]

local plugin = {}
plugin.name = 'topic'
plugin.category = 'admin'
plugin.description = 'Manage forum topics'
plugin.commands = { 'topic' }
plugin.help = '/topic <create|close|reopen|delete|rename> [name] - Manage forum topics.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    if not message.chat.is_forum then
        return api.send_message(message.chat.id, 'This command only works in forum-enabled groups.')
    end

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Usage:\n/topic create <name>\n/topic close\n/topic reopen\n/topic delete\n/topic rename <name>')
    end

    local subcommand, args = message.args:match('^(%S+)%s*(.*)')
    subcommand = subcommand:lower()

    local topic_id = message.message_thread_id

    if subcommand == 'create' then
        if not args or args == '' then
            return api.send_message(message.chat.id, 'Usage: /topic create <name>')
        end
        local result = api.create_forum_topic(message.chat.id, args)
        if result and result.result then
            return api.send_message(message.chat.id, string.format(
                'Topic "<b>%s</b>" created.',
                require('telegram-bot-lua.tools').escape_html(args)
            ), 'html')
        end
        return api.send_message(message.chat.id, 'Failed to create topic.')

    elseif subcommand == 'close' then
        if not topic_id then
            return api.send_message(message.chat.id, 'Send this command inside the topic you want to close.')
        end
        local result = api.close_forum_topic(message.chat.id, topic_id)
        if result then
            return api.send_message(message.chat.id, 'Topic closed.')
        end
        return api.send_message(message.chat.id, 'Failed to close topic.')

    elseif subcommand == 'reopen' then
        if not topic_id then
            return api.send_message(message.chat.id, 'Send this command inside the topic you want to reopen.')
        end
        local result = api.reopen_forum_topic(message.chat.id, topic_id)
        if result then
            return api.send_message(message.chat.id, 'Topic reopened.')
        end
        return api.send_message(message.chat.id, 'Failed to reopen topic.')

    elseif subcommand == 'delete' then
        if not topic_id then
            return api.send_message(message.chat.id, 'Send this command inside the topic you want to delete.')
        end
        local result = api.delete_forum_topic(message.chat.id, topic_id)
        if result then
            return -- topic deleted, can't send message to it
        end
        return api.send_message(message.chat.id, 'Failed to delete topic.')

    elseif subcommand == 'rename' then
        if not topic_id then
            return api.send_message(message.chat.id, 'Send this command inside the topic you want to rename.')
        end
        if not args or args == '' then
            return api.send_message(message.chat.id, 'Usage: /topic rename <new name>')
        end
        local result = api.edit_forum_topic(message.chat.id, topic_id, args)
        if result then
            return api.send_message(message.chat.id, string.format(
                'Topic renamed to "<b>%s</b>".',
                require('telegram-bot-lua.tools').escape_html(args)
            ), 'html')
        end
        return api.send_message(message.chat.id, 'Failed to rename topic.')

    else
        return api.send_message(message.chat.id, 'Unknown subcommand. Use: create, close, reopen, delete, rename')
    end
end

return plugin
