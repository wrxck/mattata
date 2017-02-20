--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local time = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')

function time:init()
    time.commands = mattata.commands(
        self.info.username
    ):command('time').table
    time.help = [[/time [location] - If no arguments are given; the current time, date, and timezone for your location are sent (if applicable). Otherwise, the current time, date and timezone for the given location is returned. The returned location is the first relevant result on Google Maps for the given search query.]]
end

function time.format_float(n)
    if n % 1 == 0 then
        return tostring(math.floor(n))
    else
        return tostring(n)
    end
end

function time.search(input)
    local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input))
    if res ~= 200 then
        return nil
    end
    local jdat = json.decode(jstr)
    if not jdat then
        return nil
    elseif jdat.status == 'ZERO_RESULTS' then
        return false
    end
    return jdat.results[1].geometry.location.lat, jdat.results[1].geometry.location.lng, jdat.results[1].formatted_address
end

function time:on_message(message, configuration)
    local input = mattata.input(message.text)
    local lat, lon, address
    if not input then
        if message.reply_to_message then
            message.from = message.reply_to_message.from
        end
        local location = setloc.get_loc(message.from)
        if not location then
            return mattata.send_reply(
                message,
                time.help
            )
        end
        lat, lon, address = json.decode(location).latitude, json.decode(location).longitude, json.decode(location).address
    else
        lat, lon, address = time.search(input)
        if lat == nil then
            return mattata.send_reply(
                message,
                configuration.errors.connection
            )
        elseif not lat then
            return mattata.send_reply(
                message,
                configuration.errors.results
            )
        end
    end
    local now = os.time()
    local utc = os.time(
        os.date(
            '!*t',
            now
        )
    )
    local url = string.format(
        'https://maps.googleapis.com/maps/api/timezone/json?location=%s,%s&timestamp=%s',
        lat,
        lon,
        utc
    )
    local jstr, res = https.request(url)
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
    elseif not jdat.dstOffset then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local timestamp = now + jdat.rawOffset + jdat.dstOffset
    local utc_offset = (jdat.rawOffset + jdat.dstOffset) / 3600
    if utc_offset == math.abs(utc_offset) then
        utc_offset = '+' .. time.format_float(utc_offset)
    else
        utc_offset = time.format_float(utc_offset)
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '%s\n%s\n%s (UTC%s)',
            '<b>Current time in ' .. mattata.escape_html(address) .. ':</b>',
            os.date(
                '!%I:%M %p\n%A, %B %d, %Y',
                timestamp
            ),
            jdat.timeZoneName,
            utc_offset
        ),
        'html'
    )
end

return time