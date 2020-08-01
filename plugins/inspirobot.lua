--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local inspirobot = {}
local mattata = require('mattata')
local https = require('ssl.https')
local ltn12 = require('ltn12')

function inspirobot:init()
    inspirobot.commands = mattata.commands(self.info.username):command('inspirobot'):command('ib').table
    inspirobot.help = '/inspirobot - Returns an AI-generated inspirational quote, for endless enrichment of pointless human existence. Alias: /ib.'
end

function inspirobot.on_message(_, message)
    -- Try to mimic a normal browser's headers, don't want CF getting funny with us
    local url = {}
    local _, res = https.request({
        ['url'] = 'https://inspirobot.me/api?generate=true',
        ['method'] = 'GET',
        ['headers'] = {
            [':authority:'] = 'inspirobot.me',
            [':method:'] = 'GET',
            [':path:'] = '/api?generate=true',
            [':scheme:'] = 'HTTPS',
            ['dnt'] = 1,
            ['referer'] = 'https://inspirobot.me/',
            ['sec-fetch-dest:'] = 'empty',
            ['sec-fetch-mode'] = 'cors',
            ['sec-fetch-site'] = 'same-origin',
            ['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.116 Safari/537.36 Edg/83.0.478.58'
        },
        ['sink'] = ltn12.sink.table(url)
    })
    url = table.concat(url)
    if res ~= 200 or not url:match('^https://generated%.inspirobot%.me/a/.-%.[jp][pn]e?g$') then
        return mattata.send_reply(message, 'I have nothing to say today.')
    end
    return mattata.send_photo(message.chat.id, url)
end

return inspirobot
