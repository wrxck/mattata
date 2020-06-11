--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ispwned = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function ispwned:init()
    ispwned.commands = mattata.commands(self.info.username):command('ispwned').table
    ispwned.help = '/ispwned <account> - Returns the existence of the given account in any major data leaks.'
end

function ispwned:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            ispwned.help
        )
    end
    local jstr, res = https.request('https://haveibeenpwned.com/api/v2/breachedaccount/' .. url.escape(input))
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    local jdat = json.decode(jstr)
    local output = ''
    for n in pairs(jdat)
    do
        output = output .. '\n' .. mattata.escape_html(jdat[n].Title)
    end
    return mattata.send_message(
        message.chat.id,
        '<b>' .. language['ispwned']['1'] .. '</b>\n' .. output,
        'html'
    )
end

return ispwned