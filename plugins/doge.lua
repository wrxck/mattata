--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local doge = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function doge:init()
    doge.commands = mattata.commands(
        self.info.username
    ):command('doge')
     :command('dogify').table
    doge.help = '/doge <text> - Doge-ifies the given text. Sentences should be separated using slashes or new lines. Example: /doge hello world/this is a test sentence/make sure you type like this/else it won\'t work! Alias: /dogify.'
end

function doge:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(
            message,
            'Please enter the text you want to Doge-ify. Each sentence should be separated using slashes or new lines.'
        )
        if success then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/doge'
            )
        end
        return
    end
    local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
    if not url:match('https?://[%%%w-_%.%?%.:/%+=&]+') == url then -- Validate the URL.
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