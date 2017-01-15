--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local doge = {}

local mattata = require('mattata')

function doge:init(configuration)
    doge.arguments = 'doge <text>'
    doge.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('doge').table
    doge.help = '/doge <text> - Doge-ifies the given text. Sentences are separated using slashes. Example: ' .. configuration.command_prefix .. 'doge hello world\nthis is a test sentence\nmake sure you type like this\nelse it won\'t work!'
end

function doge:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            doge.help
        )
    end
    local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
    if not url:match('https?://[%%%w-_%.%?%.:/%+=&]+') == url then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    return mattata.send_photo(
        message.chat.id,
        url
    )
end

return doge