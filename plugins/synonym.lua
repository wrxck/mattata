--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local synonym = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function synonym:init(configuration)

    assert(
        configuration.keys.synonym,
        'synonym.lua requires an API key, and you haven\'t got one configured!'
    )

    synonym.arguments = 'synonym <word>'
    synonym.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('synonym').table
    synonym.help = '/synonym <word> - Sends a synonym of the given word.'
end

function synonym:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            synonym.help
        )
    end
    local jstr, res = https.request('https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=' .. configuration.keys.synonym .. '&lang=' .. configuration.language .. '-' .. configuration.language .. '&text=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jstr == '{"head":{},"def":[]}' then
        return mattata.send_message(
            message,
            language.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        'You could use the word <b>' .. mattata.escape_html(jdat.def[1].tr[1].text) .. '</b>, instead of ' .. mattata.escape_html(input) .. '.',
        'html'
    )
end

return synonym