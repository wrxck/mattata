--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local isup = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')

function isup:init(configuration)
    isup.arguments = 'isup <url>'
    isup.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('isup').table
    isup.help = '/isup <url> - Check if the specified url is down for everyone or just for you.'
end

function isup.is_site_up(input)
    local protocol = http
    if input:lower():match('^https') then
        protocol = https
    elseif not input:lower():match('^http') then
        input = 'http://' .. input
    end
    local _, res = protocol.request(input)
    res = tonumber(res)
    if not res or res > 399 then
        return false
    end
    return true
end

function isup:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            isup.help
        )
    end
    if isup.is_site_up(input) then
        return mattata.send_reply(
            message,
            [[This website is up, maybe it's just you?]]
        )
    end
    return mattata.send_reply(
        message,
        [[It's not just you, this website is down!]]
    )
end

return isup