--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local flip = {}
local mattata = require('mattata')

function flip:init()
    flip.commands = mattata.commands(self.info.username):command('flip'):command('reverse').table
    flip.help = '/flip [text] - Repeats the replied-to/given string of text, in reverse. Alias: /reverse.'
end

function flip.on_message(_, message)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, flip.help)
    end
    local chars = {}
    local ignore = {
        ['('] = ')',
        [')'] = '(',
        ['{'] = '}',
        ['}'] = '{',
        ['['] = ']',
        [']'] = '[',
        ['>'] = '<',
        ['<'] = '>',
        ['/'] = '\\',
        ['\\'] = '/'
    }
    for char in input:gmatch('.') do
        char = ignore[char] or char
        table.insert(chars, 1, char)
    end
    local output = table.concat(chars)
    local success = mattata.send_message(message.chat.id, output)
    if not success then
        return mattata.send_reply(message, 'I can\'t flip messages with special UTF-8 codepoints in (i.e. Emoji).')
    end
    return success
end

return flip