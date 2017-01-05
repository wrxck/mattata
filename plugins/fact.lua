--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local fact = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function fact:init(configuration)
    fact.arguments = 'fact'
    fact.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('fact').table
    fact.help = configuration.command_prefix .. 'fact - Returns a random fact!'
end

function fact:on_message(message, configuration, language)
    local jstr, res = http.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        jdat[math.random(#jdat)].nid:gsub('&lt;', '<'):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', '')
    )
end

return fact