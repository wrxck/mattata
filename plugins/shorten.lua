--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local shorten = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local configuration = require('configuration')

function shorten:init(configuration)
    shorten.arguments = 'shorten <url>'
    shorten.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('shorten').table
    shorten.help = configuration.command_prefix .. 'shorten <url> - Shortens the given URL using a choice of multiple URL shorteners.'
end

function shorten.get_keyboard()
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'goo.gl',
                ['callback_data'] = 'shorten:googl'
            },
            {
                ['text'] = 'adf.ly',
                ['callback_data'] = 'shorten:adfly'
            }
        }
    }
    return keyboard
end

function shorten.googl(input)
    local body = json.encode(
        {
            ['longUrl'] = tostring(input)
        }
    )
    local response = {}
    local _, res = https.request(
        {
            ['url'] = 'https://www.googleapis.com/urlshortener/v1/url?key=' .. configuration.keys.google,
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'application/json',
                ['Content-Length'] = body:len()
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.id then
        return false
    end
    return jdat.id
end

function shorten.adfly(input)
    local body = '_api_key=' .. configuration.keys.adfly.apikey .. '&_user_id=' .. configuration.keys.adfly.userid .. '&domain=adf.ly&url=' .. input .. '&advert_type=1'
    local response = {}
    local _, res = https.request(
        {
            ['url'] = 'https://api.adf.ly/v1/shorten',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'application/x-www-form-urlencoded',
                ['Content-Length'] = body:len()
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.data[1] then
        return false
    end
    return jdat.data[1].short_url
end
    
function shorten:on_callback_query(callback_query, message)
    local input = mattata.input(message.reply_to_message.text)
    if not input then
        return false
    end
    local keyboard = shorten.get_keyboard()
    local output
    if callback_query.data == 'googl' then
        output = shorten.googl(input)
    elseif callback_query.data == 'adfly' then
        output = shorten.adfly(input)
    end
    if not output then
        return mattata.answer_callback_query(
            callback_query.id,
            'An error occured!'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        nil,
        true,
        json.encode(keyboard)
    )
end

function shorten:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            shorten.help
        )
    end
    local keyboard = shorten.get_keyboard()
    return mattata.send_message(
        message.chat.id,
        'Please select a URL shortener using the buttons below:',
        nil,
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return shorten