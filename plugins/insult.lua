--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local insult = {}

local mattata = require('mattata')
local http = require('socket.http')

function insult:init(configuration)
    insult.arguments = 'insult'
    insult.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('insult').table
    insult.help = configuration.command_prefix .. 'insult - Sends a random insult.'
end

function insult:on_message(message, configuration, language)
    local str, res = http.request('http://datahamster.com/autoinsult/index.php?style=' .. math.random(0, 3))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local output = str:match('%<div class%=%"insult%" id%=%"insult%"%>(.-)%<%/div%>')
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        output
    )
end

return insult