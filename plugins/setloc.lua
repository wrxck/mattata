--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setloc = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('libs.redis')
local configuration = require('configuration')

function setloc:init(configuration)
    assert(configuration.keys.location, 'You must set your configuration key for plugins/setloc.mattata! This can be done in configuration.lua')
    setloc.commands = mattata.commands(self.info.username):command('setloc').table
    setloc.help = '/setloc <location> - Sets your location to the given value.'
    setloc.url = 'https://api.opencagedata.com/geocode/v1/json?key='
    setloc.api_key = configuration.keys.location
end

function setloc.check_loc(location, language)
    local jstr, res = https.request(setloc.url .. setloc.api_key .. '&pretty=0&q=' .. url.escape(location))
    if res ~= 200 then
        return false, language.errors.connection
    end
    local jdat = json.decode(jstr)
    if jdat.total_results == 0 then
        return false, language.errors.results
    end
    return true, jdat.results[1].geometry.lat .. ':' .. jdat.results[1].geometry.lng .. ':' .. jdat.results[1].formatted
end

function setloc.set_loc(user_id, location, language)
    local val, res = setloc.check_loc(location, language)
    if not val then
        return res
    end
    local latitude, longitude, address = res:match('^(.-):(.-):(.-)$')
    local user_location = json.encode(
        {
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['address'] = address
        }
    )
    redis:hset('user:' .. user_id .. ':info', 'location', user_location)
    return 'Your location has been updated to: ' .. address .. '\nYou can now use commands such as /weather and /location, without needing to specify a location - your location will be used by default. Giving a different location as the command argument will override this.'
end

function setloc.get_loc(user_id)
    return redis:hget('user:' .. user_id .. ':info', 'location')
end

function setloc:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        local location = setloc.get_loc(message.from.id)
        if not location then
            return mattata.send_reply(message, 'You don\'t have a location set. Use /setloc <location> to set one.')
        end
        return mattata.send_reply(message, 'Your location is currently set to: ' .. json.decode(location).address)
    end
    local output = setloc.set_loc(message.from.id, input, language)
    return mattata.send_message(message.chat.id, output)
end

return setloc