--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local bing = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local mime = require('mime')
local json = require('dkjson')

function bing:init(configuration)
    assert(
        configuration.keys.bing,
        'bing.lua requires an API key, and you haven\'t got one configured!'
    )
    bing.commands = mattata.commands(self.info.username):command('bing').table
    bing.help = '/bing <query> - Searches Bing for the given search query and returns the top results.'
end

function bing:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            bing.help
        )
    end
    local body = {}
    local _, res = https.request(
        {
            ['url'] = 'https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=\'' .. url.escape(input) .. '\'&$format=json',
            ['headers'] = {
                ['Authorization'] = 'Basic ' .. mime.b64(':' .. configuration.keys.bing)
            },
            ['sink'] = ltn12.sink.table(body),
        }
    )
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(table.concat(body))
    local limit = message.chat.type == 'private'
    and 8
    or 4
    if limit > #jdat.d.results
    and #jdat.d.results
    or limit == 0
    then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local results = {}
    for i = 1, limit
    do
        table.insert(
            results,
            '• <a href="' .. jdat.d.results[i].Url .. '">' .. mattata.escape_html(jdat.d.results[i].Title) .. '</a>'
        )
    end
    return mattata.send_message(
        message.chat.id,
        table.concat(
            results,
            '\n'
        ),
        'html'
    )
end

return bing