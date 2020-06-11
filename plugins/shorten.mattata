--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local shorten = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local configuration = require('configuration')

function shorten:init()
    shorten.commands = mattata.commands(self.info.username):command('shorten').table
    shorten.help = '/shorten <url> - Shortens the given URL using one of the given URL shorteners.'
end

function shorten.get_keyboard()
    return mattata.inline_keyboard():row(
        mattata.row()
        :callback_data_button(
            'goo.gl',
            'shorten:googl'
        )
        :callback_data_button(
            'adf.ly',
            'shorten:adfly'
        )
    )
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
            ['url'] = 'https://www.googleapis.com/urlshortener/v1/url?key=' .. configuration.keys.google.api_key,
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'application/json',
                ['Content-Length'] = body:len()
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200
    then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.id
    then
        return false
    end
    return jdat.id
end

function shorten.adfly(input)
    local body = '_api_key=' .. configuration.keys.adfly.api_key .. '&_user_id=' .. configuration.keys.adfly.user_id .. '&domain=adf.ly&url=' .. input .. '&advert_type=1'
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
    if res ~= 200
    then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.data[1]
    then
        return false
    end
    return jdat.data[1].short_url
end

function shorten:on_callback_query(callback_query, message, configuration, language)
    local input = mattata.input(message.reply.text)
    if not input
    then
        return false
    end
    local output
    if callback_query.data == 'googl'
    then
        output = shorten.googl(input)
    elseif callback_query.data == 'adfly'
    then
        output = shorten.adfly(input)
    end
    if not output
    then
        return mattata.answer_callback_query(
            callback_query.id,
            language['errors']['generic']
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        nil,
        true,
        shorten.get_keyboard()
    )
end

function shorten:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            shorten.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        language['shorten']['1'],
        nil,
        true,
        false,
        message.message_id,
        shorten.get_keyboard()
    )
end

return shorten