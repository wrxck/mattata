--[[
    mattata v2.0 - Time Plugin
    Shows current time and date for a location.
    Geocodes via Nominatim, then uses timeapi.io for timezone lookup.
    Supports stored locations from setloc.
]]

local plugin = {}
plugin.name = 'time'
plugin.category = 'utility'
plugin.description = 'Get current time for a location'
plugin.commands = { 'time', 't', 'date', 'd' }
plugin.help = '/time [location] - Get the current time and date for a location. Uses your saved location if none is specified.'

local https = require('ssl.https')
local json = require('dkjson')
local url = require('socket.url')
local ltn12 = require('ltn12')
local tools = require('telegram-bot-lua.tools')

local function geocode(query)
    local encoded = url.escape(query)
    local request_url = 'https://nominatim.openstreetmap.org/search?q=' .. encoded .. '&format=json&limit=1&addressdetails=1'
    local body = {}
    local _, code = https.request({
        url = request_url,
        sink = ltn12.sink.table(body),
        headers = {
            ['User-Agent'] = 'mattata-telegram-bot/2.0'
        }
    })
    if code ~= 200 then
        return nil, 'Geocoding request failed.'
    end
    local data = json.decode(table.concat(body))
    if not data or #data == 0 then
        return nil, 'Location not found. Please check the spelling and try again.'
    end
    return {
        lat = tonumber(data[1].lat),
        lon = tonumber(data[1].lon),
        name = data[1].display_name
    }
end

local function get_timezone(lat, lon)
    -- Use timeapi.io to get timezone from coordinates
    local request_url = string.format(
        'https://timeapi.io/api/TimeZone/coordinate?latitude=%.6f&longitude=%.6f',
        lat, lon
    )
    local body = {}
    local _, code = https.request({
        url = request_url,
        sink = ltn12.sink.table(body),
        headers = {
            ['User-Agent'] = 'mattata-telegram-bot/2.0'
        }
    })
    if code ~= 200 then
        return nil, 'Timezone lookup failed.'
    end
    local data = json.decode(table.concat(body))
    if not data or not data.timeZone then
        return nil, 'Could not determine timezone for this location.'
    end
    return data
end

local function format_day_suffix(day)
    local d = tonumber(day)
    if d == 1 or d == 21 or d == 31 then return 'st'
    elseif d == 2 or d == 22 then return 'nd'
    elseif d == 3 or d == 23 then return 'rd'
    else return 'th'
    end
end

function plugin.on_message(api, message, ctx)
    local input = message.args
    local lat, lon, location_name

    if not input or input == '' then
        -- Try stored location
        local result = ctx.db.call('sp_get_user_location', { message.from.id })
        if result and result[1] then
            lat = tonumber(result[1].latitude)
            lon = tonumber(result[1].longitude)
            location_name = result[1].address or string.format('%.4f, %.4f', lat, lon)
        else
            return api.send_message(
                message.chat.id,
                'Please specify a location or set your default with /setloc.\nUsage: <code>/time London</code>',
                'html'
            )
        end
    else
        local geo, err = geocode(input)
        if not geo then
            return api.send_message(message.chat.id, err)
        end
        lat = geo.lat
        lon = geo.lon
        location_name = geo.name
    end

    local tz_data, err = get_timezone(lat, lon)
    if not tz_data then
        return api.send_message(message.chat.id, err)
    end

    local timezone = tz_data.timeZone or 'Unknown'
    local current_time = tz_data.currentLocalTime or ''
    local utc_offset = tz_data.currentUtcOffset and tz_data.currentUtcOffset.seconds or 0
    local dst_active = tz_data.hasDayLightSaving and tz_data.isDayLightSavingActive

    -- Parse the datetime string (format: "2024-01-15T14:30:00.0000000")
    local year, month, day, hour, min, sec = current_time:match('(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')

    if not year then
        return api.send_message(message.chat.id, 'Failed to parse time data from the API.')
    end

    local months = { 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December' }
    local days_of_week = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }

    -- Calculate day of week using Tomohiko Sakamoto's algorithm
    local y, m, d = tonumber(year), tonumber(month), tonumber(day)
    local t_table = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
    if m < 3 then y = y - 1 end
    local dow = (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + t_table[m] + d) % 7 + 1

    local day_suffix = format_day_suffix(day)
    local offset_hours = utc_offset / 3600
    local offset_str
    if offset_hours >= 0 then
        offset_str = string.format('+%g', offset_hours)
    else
        offset_str = string.format('%g', offset_hours)
    end

    local lines = {
        '<b>' .. tools.escape_html(location_name) .. '</b>',
        '',
        string.format('Time: <b>%s:%s:%s</b>', hour, min, sec),
        string.format('Date: <b>%s, %d%s %s %s</b>',
            days_of_week[dow],
            tonumber(day), day_suffix,
            months[tonumber(month)],
            year
        ),
        string.format('Timezone: <code>%s</code> (UTC%s)', tools.escape_html(timezone), offset_str)
    }

    if dst_active then
        table.insert(lines, 'DST: Active')
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
