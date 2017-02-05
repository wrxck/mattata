--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local ispwned = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function ispwned:init(configuration)
    ispwned.arguments = 'ispwned <username/email>'
    ispwned.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('ispwned').table
    ispwned.help = '/ispwned <username/email> - Tells you if the given username/email has been identified in any data leaks.'
end

function ispwned:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            ispwned.help
        )
    end
    local jstr, res = https.request('https://haveibeenpwned.com/api/v2/breachedaccount/' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local output, summary
    for n in pairs(jdat) do
        if n == 1 then
            summary = '<b>' .. language.found_one_pwned_account .. ':</b>\n'
            output = mattata.escape_html(jdat[n].Title)
        else
            summary = '<b>' .. language.account_found_multiple_leaks:gsub('X', #jdat) .. ':</b>\n'
            output = output .. mattata.escape_html(jdat[n].Title)
        end
        if n < #jdat then
            output = output .. '\n'
        end
    end
    return mattata.send_message(
        message.chat.id,
        summary .. '\n' .. output,
        'html'
    )
end

return ispwned