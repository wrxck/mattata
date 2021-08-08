--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local medium = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function medium:init()
    medium.commands = mattata.commands(self.info.username):command('medium'):command('m').table
    medium.help = '/medium <query> - Returns Medium posts matching the given search query. Alias: /m.'
end

function medium.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, medium.help)
    end

    local json_data = medium.fetch_json_data(input)
    local post = json.encode(json_data.posts[1], {indent=true})
    mattata.save_to_file(post, '/home/matt/matticatebot/medium.json')
end

function medium.fetch_json_data(input)
    local html, http_status = https.request('https://medium.com/search?q=' .. url.escape(input))
    if http_status ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end

    local json_str = html:match('<!%[CDATA%[\nwindow%["obvInit"%]%(({.-}})%)\n// %]%]>')
    if not json_str then
        return mattata.send_reply(message, language.errors.results)
    end

    return json.decode(json_str)
end

return medium