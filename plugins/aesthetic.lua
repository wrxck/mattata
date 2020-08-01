--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local aesthetic = {}
local mattata = require('mattata')
local copypasta = require('plugins.copypasta')

function aesthetic:init()
    aesthetic.commands = mattata.commands(self.info.username):command('aesthetic'):command('fullwidth'):command('fw').table
    aesthetic.help = '/aesthetic [text] - Aestheticises the given/replied-to text! Aliases: /fullwidth, /fw.'
end

function aesthetic.on_message(_, message)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, aesthetic.help)
    end
    local output = copypasta.aestheticise(input)
    return mattata.send_message(message.chat.id, output)
end

return aesthetic