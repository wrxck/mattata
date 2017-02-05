--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local author = {}

local mattata = require('mattata')

function author:init(configuration)
    author.arguments = 'author'
    author.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('author')
     :command('origin').table
    author.help = '/author - Returns the numerical ID of the original sender of the replied-to file. Alias: /origin.'
end

function author:on_message(message, configuration)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            author.help
        )
    elseif not message.reply_to_message.is_media then
        return mattata.send_reply(
            message,
            'The replied-to message must be a file!'
        )
    end
    local success = mattata.get_chat_by_file_pwr(message.reply_to_message.file_id)
    if not success or not success.result then
        return mattata.send_reply(
            message,
            'I couldn\'t get information about that file\'s original sender.'
        )
    elseif not success.result.additional and self.result.user_id then
        return mattata.send_reply(
            message,
            'I couldn\'t get information about that file\'s original sender. <code>[' .. success.result.user_id .. ']</code>',
            'html'
        )
    end
    local res = success.result.additional
    local name = '<b>Name:</b> ' .. mattata.escape_html(res.first_name)
    if res.last_name then
        name = name .. ' ' .. mattata.escape_html(res.last_name)
    end
    name = name .. '\n'
    local last_seen = ''
    if res.when then
        last_seen = '<b>Last seen:</b> ' .. res.when .. '\n'
    end
    local username = ''
    if res.username then
        username = '<b>Username:</b> @' .. res.username .. '\n'
    end
    local id = '<b>ID:</b> ' .. res.id .. '\n'
    return mattata.send_reply(
        message.reply_to_message,
        name .. username .. id .. last_seen,
        'html'
    )
end

return author