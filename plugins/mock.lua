--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local mock = {}
local mattata = require('mattata')

function mock:init()
    mock.commands = mattata.commands(self.info.username):command('mock').table
    mock.help = '/mock [text] - Repeats the replied-to message in a moCkINg style. Alternatively, input can be given - but this won\'t override a reply.'
end

function mock.change_case(str)
    local formatted = ''
    for i = 1, #str do
        local byte = str:sub(i, i)
        if byte:match('%a') then
            if i % 2 == 1 then
                formatted = formatted .. byte:upper()
            else
                formatted = formatted .. byte:lower()
            end
        else -- Support non-alphabetic characters.
            formatted = formatted .. byte
        end
    end
    return formatted
end

function mock.on_message(_, message)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, mock.help)
    end
    local chars = {}
    for v in input:gmatch('.') do
        chars[#chars + 1] = v
    end
    local output = mock.change_case(input)
    if message.reply then
        mattata.delete_message(message.chat.id, message.message_id)
        message.message_id = message.reply.message_id
        return mattata.send_reply(message, output)
    end
    return mattata.send_message(message.chat.id, output)
end

return mock