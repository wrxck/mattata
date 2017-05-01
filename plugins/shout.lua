--[[
    Based on a plugin by topkecleon.
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local shout = {}
local mattata = require('mattata')

function shout:init()
    shout.commands = mattata.commands(self.info.username):command('shout').table
    shout.help = '/shout <text> - Shouts the given text in multiple directions!'
end

function shout:on_inline_query(inline_query)
    local input = mattata.input(inline_query.query:upper())
    if not input
    then
        return false
    end
    return mattata.answer_inline_query(
        inline_query.id,
        mattata.inline_result()
        :id()
        :type('article')
        :title('Click to send the result!')
        :input_message_content(
            mattata.input_text_message_content(
                shout.format_text(input)
            )
        )
    )
end

function shout.format_text(input)
    input = mattata.trim(input)
    local output = ''
    local increment = 0
    local length = 0
    for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)')
    do
        if length < 20
        then
            length = length + 1
            output = output .. match .. ' '
        end
    end
    length = 0
    output = output .. '\n'
    for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)')
    do
        if length < 19
        then
            local space = ''
            for _ = 1, increment
            do
                space = space .. '  '
            end
            increment = increment + 1
            length = length + 1
            output = output .. match .. ' ' .. space .. match .. '\n'
        end
    end
    return mattata.trim(output)
end

function shout:on_message(message)
    local input = mattata.input(message.text:upper())
    if not input
    then
        return mattata.send_reply(
            message,
            shout.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. shout.format_text(input) .. '</pre>',
        'html'
    )
end

return shout