--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local isp = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function isp:init(configuration)
    isp.arguments = 'isp <url>'
    isp.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('isp').table
    isp.help = configuration.command_prefix .. 'isp <url> - Sends information about the given url\'s ISP.'
end

function isp:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            isp.help
        )
    end
    local jstr, res = http.request('http://ip-api.com/json/' .. url.escape(input) .. '?lang=' .. configuration.language .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.status == 'fail' then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local output = ''
    if jdat.isp ~= '' then
        output = '<b>' .. mattata.escape_html(jdat.isp) .. '</b>\n'
    end
    if jdat.zip ~= '' then
        output = output .. jdat.zip .. '\n'
    end
    if jdat.city ~= '' then
        output = output .. mattata.escape_html(jdat.city) .. '\n'
    end
    if jdat.regionName ~= '' then
        output = output .. mattata.escape_html(jdat.regionName) .. '\n'
    end
    if jdat.country ~= '' then
        output = output .. mattata.escape(jdat.country) .. '\n'
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(input) .. ':</pre>\n' .. output,
        'html'
    )
end

return isp