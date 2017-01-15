--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local loremipsum = {}

local mattata = require('mattata')
local http = require('socket.http')

function loremipsum:init(configuration)
    loremipsum.arguments = 'loremipsum'
    loremipsum.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('loremipsum').table
    loremipsum.help = '/loremipsum - Generates a few Lorem Ipsum sentences!'
end

function loremipsum:on_message(message, configuration, language)
    local str, res = http.request('http://loripsum.net/api/1/medium/plaintext')
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

return loremipsum