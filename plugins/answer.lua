--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local answer = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('libs.redis')

function answer:init()
    answer.commands = mattata.commands(self.info.username):command('answer').table
    answer.help = '/answer <query> - Provides a quick answer to the given query. Results provided by DuckDuckGo.'
    answer.url = 'https://api.duckduckgo.com/?format=json&pretty=0&q='
end

function answer:on_message(message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return false
    elseif input:match('%d* ?[%+*%-/]') then
        message.text = '/calc ' .. input
        return mattata.on_message(self, message)
    end
    input = input:gsub('[%?!,]', '')
    local jstr, res = https.request(answer.url .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(jstr)
    if not jdat.meta and jdat.Heading == '' and not jdat.RelatedTopics[1] then
        redis:hset('ai:' .. message.chat.id .. ':' .. message.message_id, 'text', input)
        redis:hset('ai:' .. message.chat.id .. ':' .. message.message_id, 'language', language)
        return true
    end
    local output = '<b>%s</b>\n<em>%s</em>\n%s'
    local heading = jdat.Heading
    local body = jdat.AbstractText ~= '' and jdat.AbstractText or jdat.RelatedTopics[1].Text or 'Couldn\'t find a description, try sending /wiki ' .. jdat.Heading
    local via = jdat.AbstractSource ~= '' and jdat.AbstractSource or jdat.RelatedTopics[1].FirstURL
    local image = jdat.Image ~= '' and jdat.Image or jdat.RelatedTopics[1] and jdat.RelatedTopics[1].Icon.URL
    if via:lower() == 'wikipedia' then
        via = '<a href="https://en.wikipedia.org">Wikipedia</a>'
    end
    via = 'Via ' .. via .. '.'
    if body:find(' /wiki ') then -- If we're re-directing them to the Wikipedia command, we don't want to give them a via message.
        return mattata.send_reply(message, 'I couldn\'t find an answer for that, try /wiki ' .. heading .. '.')
    end
    output = string.format(output, mattata.escape_html(heading), mattata.escape_html(body), via)
    if image and image ~= '' then
        return mattata.send_photo(message.chat.id, image, output, 'html', false, message.message_id)
    end
    return mattata.send_reply(message, output, 'html', true)
end

return answer