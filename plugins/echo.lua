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
    ):command('echo'):command('bigtext').table
    echo.help = '/echo <text> - Repeats a string of text.\n' .. configuration.command_prefix .. 'bigtext <text> - Converts standard text into large letters.'
end

function echo:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            echo.help
        )
    end
    local output = input
    if message.text_lower:match('^' .. configuration.command_prefix .. 'bigtext') then
        output = output:lower()
        output = output:gsub('a', '🇦 ')
                       :gsub('b', '🇧 ')
                       :gsub('c', '🇨 ')
                       :gsub('d', '🇩 ')
                       :gsub('e', '🇪 ')
                       :gsub('f', '🇫 ')
                       :gsub('g', '🇬 ')
                       :gsub('h', '🇭 ')
                       :gsub('i', '🇮 ')
                       :gsub('j', '🇯 ')
                       :gsub('k', '🇰 ')
                       :gsub('l', '🇱 ')
                       :gsub('m', '🇲 ')
                       :gsub('n', '🇳 ')
                       :gsub('o', '🇴 ')
                       :gsub('p', '🇵 ')
                       :gsub('q', '🇶 ')
                       :gsub('r', '🇷 ')
                       :gsub('s', '🇸 ')
                       :gsub('t', '🇹 ')
                       :gsub('u', '🇺 ')
                       :gsub('v', '🇻 ')
                       :gsub('w', '🇼 ')
                       :gsub('x', '🇽 ')
                       :gsub('y', '🇾 ')
                       :gsub('z', '🇿 ')
    end
    return mattata.send_message(
        message.chat.id,
        output
    )
end

return echo