--[[
    mattata v2.0 - Weather Plugin
    Shows current weather for a location using Open-Meteo (no API key needed).
    Geocodes via Nominatim (OpenStreetMap). Supports stored locations from setloc.
]]

local plugin = {}
plugin.name = 'weather'
plugin.category = 'utility'
plugin.description = 'Get current weather for a location'
plugin.commands = { 'weather' }
plugin.help = '/weather [location] - Get current weather for a location. If no location is given, your saved location is used (set with /setloc).'

local http = require('src.core.http')
local url = require('socket.url')
local tools = require('telegram-bot-lua.tools')

-- WMO weather codes to human-readable descriptions
local WMO_CODES = {
    [0] = 'Clear sky',
    [1] = 'Mainly clear',
    [2] = 'Partly cloudy',
    [3] = 'Overcast',
    [45] = 'Foggy',
    [48] = 'Depositing rime fog',
    [51] = 'Light drizzle',
    [53] = 'Moderate drizzle',
    [55] = 'Dense drizzle',
    [56] = 'Light freezing drizzle',
    [57] = 'Dense freezing drizzle',
    [61] = 'Slight rain',
    [63] = 'Moderate rain',
    [65] = 'Heavy rain',
    [66] = 'Light freezing rain',
    [67] = 'Heavy freezing rain',
    [71] = 'Slight snowfall',
    [73] = 'Moderate snowfall',
    [75] = 'Heavy snowfall',
    [77] = 'Snow grains',
    [80] = 'Slight rain showers',
    [81] = 'Moderate rain showers',
    [82] = 'Violent rain showers',
    [85] = 'Slight snow showers',
    [86] = 'Heavy snow showers',
    [95] = 'Thunderstorm',
    [96] = 'Thunderstorm with slight hail',
    [99] = 'Thunderstorm with heavy hail'
}

local function geocode(query)
    local encoded = url.escape(query)
    local request_url = 'https://nominatim.openstreetmap.org/search?q=' .. encoded .. '&format=json&limit=1&addressdetails=1'
    local data, _ = http.get_json(request_url)
    if not data then
        return nil, 'Geocoding request failed.'
    end
    if #data == 0 then
        return nil, 'Location not found. Please check the spelling and try again.'
    end
    return {
        lat = tonumber(data[1].lat),
        lon = tonumber(data[1].lon),
        name = data[1].display_name
    }
end

local function get_weather(lat, lon)
    local request_url = string.format(
        'https://api.open-meteo.com/v1/forecast?latitude=%.6f&longitude=%.6f'
        .. '&current=temperature_2m,relative_humidity_2m,apparent_temperature'
        .. ',weather_code,wind_speed_10m,wind_direction_10m'
        .. '&temperature_unit=celsius&wind_speed_unit=kmh',
        lat, lon
    )
    local data, _ = http.get_json(request_url)
    if not data or not data.current then
        return nil, 'Weather API request failed.'
    end
    return data.current
end

local function c_to_f(c)
    return c * 9 / 5 + 32
end

local function wind_direction(degrees)
    local dirs = { 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW' }
    local idx = math.floor((degrees / 22.5) + 0.5) % 16 + 1
    return dirs[idx]
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
                'Please specify a location or set your default with /setloc.\nUsage: <code>/weather London</code>',
                { parse_mode = 'html' }
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

    local weather, err = get_weather(lat, lon)
    if not weather then
        return api.send_message(message.chat.id, err)
    end

    local temp_c = weather.temperature_2m or 0
    local feels_c = weather.apparent_temperature or 0
    local humidity = weather.relative_humidity_2m or 0
    local wind_speed = weather.wind_speed_10m or 0
    local wind_dir = wind_direction(weather.wind_direction_10m or 0)
    local conditions = WMO_CODES[weather.weather_code] or 'Unknown'

    local output = string.format(
        '<b>Weather for %s</b>\n\n'
        .. 'Conditions: %s\n'
        .. 'Temperature: <b>%.1f°C</b> / <b>%.1f°F</b>\n'
        .. 'Feels like: %.1f°C / %.1f°F\n'
        .. 'Humidity: %d%%\n'
        .. 'Wind: %.1f km/h %s',
        tools.escape_html(location_name),
        conditions,
        temp_c, c_to_f(temp_c),
        feels_c, c_to_f(feels_c),
        humidity,
        wind_speed, wind_dir
    )

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
