--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fakeid = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function fakeid:init()
    fakeid.commands = mattata.commands(
        self.info.username
    ):command('fakeid').table
    fakeid.help = '/fakeid - Generates a fake identity.'
end

function fakeid:on_message(message, configuration)
    local jstr = io.popen('curl "https://randomuser.me/api/"'):read('*all')
    local jdat = json.decode(jstr)
    if not jdat
    then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    return mattata.send_message(
        message.chat.id,
        jdat.results[1].name.first:gsub('^%l', string.upper) .. ' ' .. jdat.results[1].name.last:gsub('^%l', string.upper)
    )
end

return fakeid