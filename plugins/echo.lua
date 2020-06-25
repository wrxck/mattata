--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local echo = {}
local mattata = require('mattata')

function echo:init()
    echo.commands = mattata.commands(self.info.username):command('echo'):command('say').table
    echo.help = '/echo <text> - Repeats the given string of text. Append -del to the end of your text to delete your command message. Alias: /say.'
end

function echo.on_message(_, message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, echo.help)
    elseif input:match(' %-d$') then
        input = input:match('^(.-) %-d$')
        mattata.delete_message(message.chat.id, message.message_id)
    end
    return mattata.send_message(message.chat.id, input)
end

return echo