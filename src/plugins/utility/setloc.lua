--[[
    mattata v2.0 - Set Location Plugin
    Geocodes an address and stores latitude/longitude for weather and time plugins.
]]

local plugin = {}
plugin.name = 'setloc'
plugin.category = 'utility'
plugin.description = 'Set your location for weather and time commands'
plugin.commands = { 'setloc', 'setlocation', 'location' }
plugin.help = '/setloc <address> - Set your location by providing an address or place name.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local https = require('ssl.https')
    local json = require('dkjson')
    local url = require('socket.url')

    local input = message.args
    if not input or input == '' then
        -- Show current location
        local result = ctx.db.execute(
            'SELECT latitude, longitude, address FROM user_locations WHERE user_id = $1',
            { message.from.id }
        )
        if result and result[1] then
            return api.send_message(
                message.chat.id,
                string.format(
                    'Your location is set to: <b>%s</b>\n(<code>%s, %s</code>)',
                    tools.escape_html(result[1].address or 'Unknown'),
                    result[1].latitude,
                    result[1].longitude
                ),
                'html'
            )
        end
        return api.send_message(message.chat.id, 'You haven\'t set a location yet. Use /setloc <address> to set one.')
    end

    -- Geocode via Nominatim
    local encoded = url.escape(input)
    local api_url = string.format(
        'https://nominatim.openstreetmap.org/search?q=%s&format=json&limit=1&addressdetails=1',
        encoded
    )
    local body, status = https.request(api_url)
    if not body or status ~= 200 then
        return api.send_message(message.chat.id, 'Failed to geocode that address. Please try again.')
    end

    local data = json.decode(body)
    if not data or #data == 0 then
        return api.send_message(message.chat.id, 'No results found for that address. Please try a different query.')
    end

    local result = data[1]
    local lat = tonumber(result.lat)
    local lng = tonumber(result.lon)
    local address = result.display_name or input

    -- Upsert into user_locations
    ctx.db.execute(
        [[INSERT INTO user_locations (user_id, latitude, longitude, address, updated_at)
          VALUES ($1, $2, $3, $4, NOW())
          ON CONFLICT (user_id) DO UPDATE
          SET latitude = $2, longitude = $3, address = $4, updated_at = NOW()]],
        { message.from.id, lat, lng, address }
    )

    return api.send_message(
        message.chat.id,
        string.format(
            'Location set to: <b>%s</b>\n(<code>%s, %s</code>)',
            tools.escape_html(address),
            lat, lng
        ),
        'html'
    )
end

return plugin
