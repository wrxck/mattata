--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local qr = {}

local mattata = require('mattata')
local url = require('socket.url')

function qr:init(configuration)
    qr.arguments = 'qr <string>'
    qr.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('qr'):command('qrcode').table
    qr.help = configuration.command_prefix .. 'qr <string> - Converts the given string to an QR code. Alias: ' .. configuration.command_prefix .. 'qrcode.'
end

function qr:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            qr.help
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        'http://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=' .. url.escape(input) .. '&chld=H|0.png'
    )
end

return qr