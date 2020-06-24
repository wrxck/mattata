--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local catfact = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')


function catfact:init()
    catfact.commands = mattata.commands(self.info.username):command('catfact'):command('cfact').table
    catfact.help = '/catfact - Returns a random cat fact. Alias: /cfact.'
end

function catfact.on_message(_, message, _, language)
    local jstr, res = https.request('https://catfact.ninja/fact')
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(message.chat.id, jdat.fact)
end

return catfact