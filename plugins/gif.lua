--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local gif = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')

function gif:init()
    gif.commands = mattata.commands(
        self.info.username
    ):command('gif')
     :command('giphy').table
    gif.help = [[/gif <query> - Searches GIPHY for the given search query and returns a random, relevant result. Alias: /giphy.]]
end

function gif:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local jstr = https.request('https://api.giphy.com/v1/gifs/search?q=' .. url.escape(input) .. '&api_key=dc6zaTOxFJmzC')
    local jdat = json.decode(jstr)
    local results = '['
    local id = 1
    for n in pairs(jdat.data) do
        results = results .. '{"type":"mpeg4_gif","id":"' .. id .. '","mpeg4_url":"' .. jdat.data[n].images.original.mp4 .. '","thumb_url":"' .. jdat.data[n].images.fixed_height.url .. '","mpeg4_width":' .. jdat.data[n].images.original.width .. ',"mp4_height":' .. jdat.data[n].images.original.height .. '}'
        id = id + 1
        if n < #jdat.data then results = results .. ',' end
    end
    local results = results .. ']'
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function gif:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(
            message,
            'Please enter a search query (that is, what you want me to search GIPHY for, i.e. "cat" will return a GIF of a cat).'
        )
        if success then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/gif'
            )
        end
        return
    end
    local jstr, res = https.request('https://api.giphy.com/v1/gifs/search?q=' .. url.escape(input) .. '&api_key=dc6zaTOxFJmzC')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.data or not jdat.data[1] then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_document(
        message.chat.id,
        jdat.data[math.random(#jdat.data)].images.original.mp4
    )
end

return gif