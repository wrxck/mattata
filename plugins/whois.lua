--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local whois = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')

function whois:init(configuration)
    whois.arguments = 'whois <IP address>'
    whois.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('whois').table
    whois.help = '/whois <IP address> - Displays the WHOIS look-up result for the given IP address.'
end

function whois:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            whois.help
        )
    end
    local str, res = https.request('https://who.is/whois-ip/ip-address/' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local output = str:match('%<pre%>(.-)%<%/pre%>')
    if not output or output:match('^No match found') then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(output) .. '</pre>',
        'html'
    )
end

return whois