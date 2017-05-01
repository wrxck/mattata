--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local donate = {}
local mattata = require('mattata')

function donate:init()
    donate.commands = mattata.commands(self.info.username):command('donate').table
    donate.help = '/donate - Make an optional, monetary contribution to the mattata project.'
end

function donate:on_message(message)
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<b>Hello, %s!</b>\n\nIf you\'re feeling generous, you can contribute to the mattata project by making a monetary donation of any amount. This will go towards server costs and any time and resources used to develop mattata. This is an optional act, however it is greatly appreciated and your name will also be listed publically on mattata\'s GitHub page.\n\nIf you\'re still interested, you can donate <a href="https://paypal.me/wrxck">here</a>. Thank you for your continued support! 😀',
            mattata.escape_html(message.from.first_name)
        ),
        'html'
    )
end

return donate