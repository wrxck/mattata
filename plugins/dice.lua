--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local dice = {}
local mattata = require('mattata')

function dice:init()
    dice.commands = mattata.commands(self.info.username):command('dice'):command('roll').table
    dice.types = {
        utf8.char(127936),
        utf8.char(127922),
        utf8.char(127919)
    }
    dice.help = '/dice [type] - Returns an animated dice roll, basketball shot or dart throw (randomly chosen). Optionally, you can specify the type via parameter (ball/dice/dart). Alias: /roll.'
end

function dice.on_message(_, message)
    local input = mattata.input(message.text)
    local output = dice.types[math.random(#dice.types)]
    if input and (input:lower() == 'basketball' or input:lower() == 'ball') then
        output = dice.types[1]
    elseif input and (input:lower() == 'dice' or input:lower() == 'die') then
        output = dice.types[2]
    elseif input and input:lower() == 'dart' then
        output = dice.types[3]
    end
    if math.random(100) == 100 then
        return mattata.send_sticker(message.chat.id, 'CAACAgQAAx0CQNYPUgABATQCXtmOk9jz2lCN7omTIjCqmLa08hUAAkAAA8j67BMAAUvGUioKrK4aBA')
    end
    return mattata.send_dice(message.chat.id, output)
end

return dice