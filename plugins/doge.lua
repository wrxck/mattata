--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local doge = {}

local mattata = require('mattata')

function doge:init()
    doge.commands = mattata.commands(
        self.info.username
    ):command('doge')
     :command('dogify').table
    doge.help = [[/doge <text> - Doge-ifies the given text. Sentences are separated using slashes. Example: /doge hello world/this is a test sentence/make sure you type like this/else it won't work! Alias: /dogify.]]
end

function doge:on_message(message, configuration)
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
            configuration.errors.results
        )
    end
    return mattata.send_photo(
        message.chat.id,
        url
    )
end

return doge