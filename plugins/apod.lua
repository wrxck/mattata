--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local apod = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function apod:init(configuration)
    assert(
        configuration.keys.apod,
        'apod.lua requires an API key, and you haven\'t got one configured!'
    )
    apod.commands = mattata.commands(self.info.username):command('apod').table
    apod.help = '/apod [dd/mm/yyyy] - Sends NASA\'s astronomy picture of the day. If a date is given, the astronomy picture for that date is returned instead.'
end

function apod:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
    local day, month, year = os.date('%d/%m/%Y'):match('^(%d%d)%/(%d%d)%/(%d%d%d%d)$')
    if input
    and input:match('^(%d%d)[%/%-](%d%d)[%/%-](%d%d%d%d)$')
    then
        day, month, year = input:match('^(%d%d)[%/%-](%d%d)[%/%-](%d%d%d%d)$')
        url = url .. '&date=' .. year .. '-' .. month .. '-' .. day
    end
    local jstr, res = https.request(url)
    if res ~= 200
    then
        return
    end
    local jdat = json.decode(jstr)
    return mattata.answer_inline_query(
        inline_query.id,
        mattata.inline_result()
        :id()
        :type('photo')
        :photo_url(
            jdat.hdurl
            or jdat.url
        )
        :thumb_url(jdat.url)
        :caption(jdat.title .. ' - ' .. day .. '/' .. month .. '/' .. year)
    )
end

function apod:on_message(message, configuration)
    local input = mattata.input(message.text)
    local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
    local day, month, year = os.date('%d/%m/%Y'):match('^(%d%d)%/(%d%d)%/(%d%d%d%d)$')
    if input
    and input:match('^(%d%d)[%/%-](%d%d)[%/%-](%d%d%d%d)$')
    then
        day, month, year = input:match('^(%d%d)[%/%-](%d%d)[%/%-](%d%d%d%d)$')
        url = url .. '&date=' .. year .. '-' .. month .. '-' .. day
    end
    local jstr, res = https.request(url)
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        jdat.url,
        jdat.title .. ' - ' .. day .. '/' .. month .. '/' .. year
    )
end

return apod