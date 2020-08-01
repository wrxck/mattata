--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local time = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')
local redis = require('libs.redis')

function time:init()
    time.commands = mattata.commands(self.info.username):command('time'):command('t'):command('d'):command('date').table
    time.help = '/time [query] - Sends your time, or the time for the given location. Aliases: /t, /d, /date.'
end

function time:on_message(message, configuration, language)
    local input = mattata.input(message.text:lower())
    local location = false
    if message.reply and not input then -- If it's used in reply to someone, we want their time instead.
        message.from = message.reply.from
    end
    if not input and not setloc.get_loc(message.from.id) then
        local success = mattata.send_force_reply(message, 'Please specify the location you would like to get the time for:')
        if success then
            local action = mattata.command_action(message.chat.id, success.result.message_id)
            redis:set(action, '/time')
        end
        return
    elseif not input then
        location = setloc.get_loc(message.from.id)
        if location then
            location = json.decode(location)
        end
    end
    if not location then
        local jstr, res = https.request('https://api.opencagedata.com/geocode/v1/json?key=' .. configuration.keys.location .. '&pretty=0&q=' .. url.escape(input))
        if res ~= 200 then
            return mattata.send_reply(message, language.errors.connection)
        end
        local jdat = json.decode(jstr)
        if jdat.total_results == 0 then
            return mattata.send_reply(message, language.errors.results)
        end
        location = {
            ['latitude'] = jdat.results[1].geometry.lat,
            ['longitude'] = jdat.results[1].geometry.lng,
            ['address'] = jdat.results[1].formatted
        }
    end
    local formatted_location = string.format('%s,%s', location.latitude, location.longitude)
    local jstr, res = https.request('https://maps.googleapis.com/maps/api/timezone/json?location=' .. formatted_location .. '&timestamp=' .. os.time() .. '&key=' .. configuration.keys.maps)
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(jstr)
    if jdat.errorMessage then
        local output = string.format('Error `%s: %s`', jdat.status, jdat.errorMessage)
        return mattata.send_message(message, output, true)
    end
    local offset = os.time() + tonumber(jdat.rawOffset) + tonumber(jdat.dstOffset)
    local current = os.date('%c', offset)
    current = current:gsub('^(%w+ %w+ %d*) (%d*:%d*:%d*) (%d+)$', '%2</b> on <b>%1 %3') -- We want the time first!
    local output = 'It is currently <b>%s</b> <code>[%s]</code> in %s.'
    output = string.format(output, current, jdat.timeZoneName, location.address)
    return mattata.send_reply(message, output, 'html')
end

return time
