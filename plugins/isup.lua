--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local isup = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function isup:init()
    isup.commands = mattata.commands(self.info.username):command('isup').table
    isup.help = '/isup <url> - Checks to see if the given URL is down for everyone or just you.'
end

function isup:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            isup.help
        )
    end
    local str, res = http.request('http://isup.me/' .. url.escape(input))
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local output = configuration.errors.connection
    if str:match('It\'s just you.')
    then
        output = 'This website appears to be up, maybe it\'s just you?'
    elseif str:match('doesn\'t look like a site')
    then
        output = 'That doesn\'t appear to be a valid site!'
    elseif str:match('looks down from here')
    then
        output = 'It\'s not just you, this website looks down from here.'
    end
    return mattata.send_reply(
        message,
        output
    )
end

return isup