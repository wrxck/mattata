--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local insult = {}
local mattata = require('mattata')
local http = require('socket.http')

function insult:init()
    insult.commands = mattata.commands(self.info.username):command('insult').table
    insult.help = '/insult - Generates a random insult.'
end

function insult:on_message(message, configuration, language)
    local str, res = http.request(
        'http://datahamster.com/autoinsult/index.php?style=' .. math.random(0, 3)
    )
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    local output = str:match('%<div class%=%"insult%" id%=%"insult%"%>(.-)%<%/div%>')
    if not output
    then
        return mattata.send_reply(
            message,
            language['errors']['results']
        )
    end
    return mattata.send_message(
        message.chat.id,
        output
    )
end

return insult