--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ping = {}
local mattata = require('mattata')

function ping:init()
    ping.commands = mattata.commands(self.info.username):command('ping'):command('pong').table
    ping.help = '/ping - PONG!'
end

function ping.on_message(_, message)
    if message.text:match('^[/!#]pong') then
        return mattata.send_reply(message, 'You really have to go the extra mile, don\'t you?')
    end
    return mattata.send_sticker(message.chat.id, 'CAADBAAD1QIAAlAYNw2Pr-ymr7r8TgI')
end

return ping
