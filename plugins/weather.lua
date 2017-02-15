--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local weather = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')

function weather:init()
    weather.commands = mattata.commands(
        self.info.username
    ):command('weather').table
    weather.help = [[/weather [location] - If no arguments are given, the weather forecast for your known location is given. If a location is given, then the weather forecast for that location is given instead.]]
end

function weather.format_temperature(temperature, units)
    temperature = tonumber(temperature)
    if units ~= 'us' then
        return temperature .. '°C/' .. string.format(
            '%.2f',
            temperature * 9 / 5 + 32
        ) .. '°F'
    else
        return temperature .. '°F/' .. string.format(
            '%.2f',
            (temperature - 32) * 5 / 9
        ) .. '°C'
    end
end

function weather.get_weather(input)
    local url = 'http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input)
    local jstr, res = http.request(url)
    if res ~= 200 then
        return false, false, false
    end
    local jdat = json.decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
        return true, false, false
    end
    return jdat.results[1].geometry.location.lat, jdat.results[1].geometry.location.lng, jdat.results[1].formatted_address
end

function weather:on_message(message, configuration)
    local input = mattata.input(message.text)
    local latitude, longitude, address
    if not input then
        local location = setloc.get_loc(message.from)
        if not location then
            return mattata.send_reply(
                message,
                'You don\'t have a location set. Use /setloc <location> to set one.'
            )
        end
        latitude, longitude, address = json.decode(location).latitude, json.decode(location).longitude, json.decode(location).address
    else
        latitude, longitude, address = weather.get_weather(input)
        if not latitude or not longitude then
            return mattata.send_reply(
                message,
                configuration.errors.results
            )
        end
    end
    local jstr, res = https.request('https://api.darksky.net/forecast/' .. configuration.keys.weather .. '/' .. latitude .. ',' .. longitude .. '?units=auto')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        'It\'s currently ' .. weather.format_temperature(jdat.currently.temperature, jdat.flags.units) .. ' (feels like ' .. weather.format_temperature(jdat.currently.apparentTemperature, jdat.flags.units) .. ') in ' .. address .. '. ' .. jdat.daily.summary
    )
end

return weather