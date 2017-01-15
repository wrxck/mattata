--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local calc = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function calc:init(configuration)
    calc.arguments = 'calc <expression>'
    calc.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('calc').table
    calc.help = '/calc <expression> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.'
end

function calc:on_inline_query(inline_query)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    input = input:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*'):gsub('to the power of', '^'):gsub('minus', '-')
    local str, res = http.request('https://api.mathjs.org/v1/?expr=' .. url.escape(input))
    if res ~= 200 then
        return
    end
    return mattata.answer_inline_query(
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = str,
                    ['description'] = 'Click to send the result.',
                    ['input_message_content'] = {
                        ['message_text'] = str
                    }
                }
            }
        )
    )
end

function calc:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            calc.help
        )
    end
    input = input:gsub('÷', '/'):gsub(' x ', '*'):gsub('x', '*'):gsub('plus', '+'):gsub('divided by', '/'):gsub('take away', '-'):gsub('times by', '*'):gsub('multiplied by', '*'):gsub('pi', math.pi):gsub('times', '*'):gsub('to the power of', '^'):gsub('minus', '-')
    local str, res = http.request('https://api.mathjs.org/v1/?expr=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    return mattata.send_message(
        message.chat.id,
        str
    )
end

return calc