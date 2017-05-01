--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local theme = {}
local mattata = require('mattata')

function theme:init()
    theme.commands = mattata.commands(self.info.username):command('theme').table
    theme.help = '/theme - Get a cool theme for Telegram Desktop & Telegram for Android, created by mattata\'s developer!'
end

function theme:on_message(message)
    return mattata.forward_message(
        message.chat.id,
        '@mattata',
        false,
        1296
    )
end

return theme