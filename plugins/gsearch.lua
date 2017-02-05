--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local gsearch = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function gsearch:init(configuration)
    gsearch.arguments = 'google <query>'
    gsearch.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('google').table
    gsearch.help = '/google <query> - Displays the top results from Google for the given search query.'
end

function gsearch:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            gsearch.help
        )
    end
    local amount = 8
    if message.chat.type ~= 'private' then
        amount = 4
    end
    local jstr, res = https.request('https://www.googleapis.com/customsearch/v1/?key=' .. configuration.keys.gsearch.api_key .. '&cx=' .. configuration.keys.gsearch.cse_key .. '&gl=en&num=' .. amount .. '&fields=items%28title,link%29&q=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.items then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local results = {}
    for _, v in ipairs(jdat.items) do
        table.insert(
            results,
            string.format(
                '• <a href="%s">%s</a>',
                mattata.escape_html(v.link),
                mattata.escape_html(v.title)
            )
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

return gsearch