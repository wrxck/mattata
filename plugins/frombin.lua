--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local frombin = {}

local mattata = require('mattata')

function frombin:init(configuration)
    frombin.arguments = 'frombin <binary>'
    frombin.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('frombin').table
    frombin.help = configuration.command_prefix .. 'frombin <binary> - Converts the given string of binary to a numerical value.'
end

function frombin:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            frombin.help
        )
    end
    local temp_input = input:gsub('0', ''):gsub('1', '')
    if temp_input ~= '' then
        return mattata.send_reply(
            message,
            'The inputted string must be in binary format.'
        )
    end
    local number = 0
    local ex = input:len() - 1
    local l = 0
    l = ex + 1
    for i = 1, l do
        b = input:sub(i, i)
        if b == '1' then
            number = number + 2^ex
        end
        ex = ex - 1
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. number .. '</pre>',
        'html'
    )
end

return frombin