--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local echo = {}
local mattata = require('mattata')

function echo:init()
    echo.commands = mattata.commands(self.info.username):command('echo'):command('say').table
    echo.help = '/echo <text> - Repeats the given string of text. Alias: /say.'
end

function echo.on_message(_, message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, echo.help)
    end
    input = string.format('<pre>%s</pre>', mattata.escape_html(input))
    return mattata.send_message(message.chat.id, input, 'html')
end

return echo