--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local location = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')
local redis = require('mattata-redis')

function location:init()
    location.commands = mattata.commands(
        self.info.username
    ):command('location')
     :command('loc').table
    location.help = [[/location [query] - Sends your location, or a location from Google Maps. Alias: /loc.]]
end

function location:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        local loc = setloc.get_loc(inline_query.from)
        if not loc then
            return
        end
        local jdat = json.decode(loc)
        return mattata.answer_inline_query(
            inline_query.id,
            json.encode(
                {
                    {
                        ['type'] = 'location',
                        ['id'] = '1',
                        ['latitude'] = tonumber(jdat.latitude),
                        ['longitude'] = tonumber(jdat.longitude),
                        ['title'] = tostring(jdat.address)
                    }
                }
            )
        )
    end
    local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input))
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
        return
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'location',
                    ['id'] = '1',
                    ['latitude'] = tonumber(jdat.results[1].geometry.location.lat),
                    ['longitude'] = tonumber(jdat.results[1].geometry.location.lng),
                    ['title'] = tostring(input)
                }
            }
        )
    )
end

function location:on_message(message, configuration)
    local input = mattata.input(message.text:lower())
    if not input and not setloc.get_loc(message.from) then
        local success = mattata.send_force_reply(
            message,
            'You don\'t have a location set. What would you like your new location to be?.'
        )
        if success then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/setloc'
            )
        end
        return
    elseif not input then
        local loc = setloc.get_loc(message.from)
        return mattata.send_location(
            message.chat.id,
            json.decode(loc).latitude,
            json.decode(loc).longitude
        )
    end
    local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    return mattata.send_location(
        message.chat.id,
        jdat.results[1].geometry.location.lat,
        jdat.results[1].geometry.location.lng
    )
end

return location