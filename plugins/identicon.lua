--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local identicon = {}

local mattata = require('mattata')
local url = require('socket.url')

function identicon:init(configuration)
    identicon.arguments = 'identicon <string>'
    identicon.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('identicon').table
    identicon.help = '/identicon <string> - Converts the given string of text to an identicon.'
end

function identicon:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            identicon.help
        )
    end
    return mattata.send_photo(
        message.chat.id,
        'http://identicon.rmhdev.net/' .. url.escape(input) .. '.png'
    )
end

return identicon