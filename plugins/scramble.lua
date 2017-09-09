--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local scramble = {}
local mattata = require('mattata')

function scramble:init()
    scramble.commands = mattata.commands(self.info.username):command('scramble').table
    scramble.help = '/scramble <text> - Scrambles the given text.'
end

function scramble:on_message(message)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            scramble.help
        )
    elseif not input:match('%S+')
    then
        return mattata.send_reply(
            message,
            'The text you entered does not contain any valid characters!'
        )
    end
    local words = {}
    for word in input:gmatch('%S+')
    do
        table.insert(words, word)
    end
    local output = {}
    local position
    for _, word in pairs(words)
    do
        position = math.random(#output > 0 and #output or 1)
        table.insert(output, position, word)
    end
    return mattata.send_message(
        message.chat.id,
        table.concat(output, ' ')
    )
end

return scramble