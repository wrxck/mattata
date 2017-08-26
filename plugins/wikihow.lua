--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local wikihow = {}
local mattata = require('mattata')
local http = require('socket.http')

function wikihow:init()
    wikihow.commands = mattata.commands(self.info.username):command('wikihow').table
    wikihow.help = '/wikihow - Sends a link for a random WikiHow article.'
end

function wikihow:on_message(message, configuration, language)
    local _, res, headers = http.request('http://www.wikihow.com/Special:Randomizer')
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    return mattata.send_message(
        message.chat.id,
        headers['location']
    )
end

return wikihow