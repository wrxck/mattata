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
    local jstr, res = https.request('https://medium.com/search?q=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    jstr = jstr:match('<!%[CDATA%[\nwindow%["obvInit"%]%(({.-}})%)\n// %]%]>')
    if not jstr then
        return mattata.send_reply(message, language.errors.results)
    end
    local jdat = json.decode(jstr)
    mattata.save_to_file(json.encode(jdat.posts[1], {indent=true}), '/home/matt/matticatebot/medium.json')
    return
end

return medium