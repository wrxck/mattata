--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local echo = {}

local mattata = require('mattata')

function echo:init(configuration)
    echo.arguments = 'echo <text>'
    echo.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('echo').table
    echo.help = configuration.command_prefix .. 'echo <text> - Repeats a string of text.'
end

function echo:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            echo.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        input
    )
end

return echo