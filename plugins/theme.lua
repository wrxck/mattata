--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local theme = {}

local mattata = require('mattata')

function theme:init()
    theme.commands = mattata.commands(
        self.info.username
    ):command('theme').table
    theme.help = [[/theme - Get a theme for Telegram Desktop created by mattata's developer!]]
end

function theme:on_message(message)
    return mattata.forward_message(
        message.chat.id,
        '@mattata',
        false,
        1090
    )
end

return theme