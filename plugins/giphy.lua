--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local giphy = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function giphy:init(configuration)
    giphy.arguments = 'gif <query>'
    giphy.commands = mattata.commands(self.info.username, configuration.command_prefix):command('gif'):command('giphy').table
    giphy.help = configuration.command_prefix .. 'gif <query> - Searches Giphy for the given query and returns a random result. Alias: ' .. configuration.command_prefix .. 'giphy.'
end

function giphy:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
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
    mattata.answer_inline_query(inline_query.id, results, 0)
end

function giphy:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then mattata.send_message(message.chat.id, giphy.help) return end
    local jstr, res = https.request('https://api.giphy.com/v1/gifs/search?q=' .. url.escape(input) .. '&api_key=dc6zaTOxFJmzC')
    if res ~= 200 then mattata.send_message(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
    local jdat = json.decode(jstr)
    if not jdat.data[1] then mattata.send_message(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
    mattata.send_chat_action(message.chat.id, 'upload_photo')
    mattata.send_document(message.chat.id, jdat.data[math.random(#jdat.data)].images.original.mp4)
end

return giphy