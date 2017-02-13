--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local duckduckgo = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function duckduckgo:init(configuration)
    duckduckgo.arguments = 'duckduckgo'
    duckduckgo.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('duckduckgo')
     :command('ddg').table
    duckduckgo.help = '/duckduckgo <query> - Searches DuckDuckGo\'s Instant Results for the given query. Alias: /ddg.'
end

function duckduckgo:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            duckduckgo.help
        )
    end
    local jstr, res = http.request('http://api.duckduckgo.com/?format=json&pretty=1&q=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.AbstractText or jdat.AbstractText == '' then
        return mattata.send_reply(
            message,
            'I\'m not sure what that is!'
        )
    end
    return mattata.send_message(
        message.chat.id,
        jdat.AbstractText
    )
end

return duckduckgo