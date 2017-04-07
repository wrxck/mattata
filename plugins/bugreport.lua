--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local bugreport = {}
local mattata = require('mattata')

function bugreport:init(configuration)
    assert(
        configuration.bug_reports_chat,
        'Please specify a chat ID to send all bug reports to!'
    )
    bugreport.commands = mattata.commands(self.info.username)
    :command('bugreport')
    :command('bug')
    :command('br').table
    bugreport.help = '/bugreport <text> - Reports a bug to the configured developer. Aliases: /bug, /br.'
end

function bugreport:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            bugreport.help
        )
    end
    if message.reply
    then
        mattata.forward_message(
            configuration.bug_reports_chat,
            message.chat.id,
            false,
            message.message_id
        )
    end
    local success = mattata.forward_message(
        configuration.bug_reports_chat,
        message.chat.id,
        false,
        message.message_id
    )
    if success
    and message.chat.id ~= configuration.bug_reports_chat
    then
        return mattata.send_reply(
            message,
            'Success! Your bug report has been sent. The ID of this report is #' .. message.date .. '.'
        )
    end
    return mattata.send_reply(
        message,
        'There was a problem whilst reporting that bug! Ha, the irony!'
    )
end

return bugreport