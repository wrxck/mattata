--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local xkcd = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function xkcd:init(configuration)
    xkcd.arguments = 'xkcd <i>'
    xkcd.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('xkcd').table
    xkcd.help = configuration.command_prefix .. 'xkcd <i> - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If \'r\' is passed in place of a number, returns a random strip.'
    xkcd.base_url = 'https://xkcd.com/info.0.json'
    xkcd.strip_url = 'http://xkcd.com/%s/info.0.json'
    local jstr = http.request(xkcd.base_url)
    if jstr then
        local jdat = json.decode(jstr)
        if jdat then
            xkcd.latest = jdat.num
        end
    end
    xkcd.latest = xkcd.latest
end

function xkcd:on_message(message, configuration, language)
    local input = mattata.get_word(message.text, 2)
    if not input then
        input = xkcd.latest
    end
    if input == 'r' then
        input = math.random(xkcd.latest)
    elseif tonumber(input) ~= nil then
        input = tonumber(input)
    else
        local link = 'https://www.google.co.uk/search?num=20&q=' .. url.escape('inurl:xkcd.com ' .. input)
        local search = https.request(link)
        local result = search:match('https?://xkcd[^/]+/(%d+)')
        if not result then
            input = xkcd.latest
        else
            input = result
        end
    end
    local url = xkcd.strip_url:format(input)
    local jstr, res = http.request(url)
    if res == 404 then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    elseif res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Read More',
                ['url'] = 'https://xkcd.com/' .. jdat.num
            }
        }
    }
    return mattata.send_photo(
        message.chat.id,
        jdat.img,
        jdat.num .. ' | ' .. jdat.safe_title .. ' | ' .. jdat.day .. '/' .. jdat.month .. '/' .. jdat.year,
        false,
        nil,
        json.encode(keyboard)
    )
end

return xkcd