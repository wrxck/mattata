--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local shout = {}

local mattata = require('mattata')

function shout:init(configuration)
    shout.arguments = 'shout <text>'
    shout.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('shout').table
    shout.help = configuration.command_prefix .. 'shout <text> - Shout something in multiple directions.'
end

function shout:on_message(message)
    local input = mattata.input(message.text_upper)
    if not input then
        return mattata.send_reply(
            message,
            shout.help
        )
    end
    input = mattata.trim(input)
    local output = ''
    local increment = 0
    local length = 0
    for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
        if length < 20 then
            length = length + 1
            output = output .. match .. ' '
        end
    end
    length = 0
    output = output .. '\n'
    for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
        if length < 19 then
            local space = ''
            for _ = 1, increment do
                space = space .. '  '
            end
            increment = increment + 1
            length = length + 1
            output = output .. match .. ' ' .. space .. match .. '\n'
        end
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.trim(output) .. '</pre>',
        'html'
    )
end

return shout