--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local belikebill = {}

local mattata = require('mattata')
local url = require('socket.url')

function belikebill:init()
    belikebill.commands = mattata.commands(
        self.info.username
    ):command('belikebill').table
    belikebill.help = '/belikebill <text> - Generates a Be Like Bill meme using the given text as the caption.'
end

function belikebill:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            belikebill.help
        )
    end
    local success = mattata.send_photo(
        message.chat.id,
        'http://belikebill.azurewebsites.net/billgen-API.php?text=' .. url.escape(input)--:gsub('%%0a', '%0d%0a')
    )
    if not success then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
end

return belikebill