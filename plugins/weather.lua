local weather = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')

function weather:init(configuration)
	weather.arguments = 'weather <location>'
	weather.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('weather').table
	weather.help = configuration.commandPrefix .. 'weather <location> - Sends the current weather for the given location.'
end

function weather.getWeather(input)
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

function weather:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	local latitude, longitude, address
	if not input then
		local location = setloc.getLocation(message.from)
		if not location then
			mattata.sendMessage(message.chat.id, 'You don\'t have a location set. Use \'' .. configuration.commandPrefix .. 'setloc <location>\' to set one.', nil, true, false, message.message_id)
			return
		end
		latitude, longitude, address = json.decode(location).latitude, json.decode(location).longitude, json.decode(location).address
	else
		latitude, longitude, address = weather.getWeather(input)
		if not latitude then
			mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
			return
		elseif not longitude then
			mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
			return
		end
	end
	local jstr, res = https.request('https://api.darksky.net/forecast/' .. configuration.keys.weather .. '/' .. latitude .. ',' .. longitude .. '?units=auto')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	local units = '°F'
	if jdat.flags.units ~= 'us' then
		units = '°C'
	end
	mattata.sendMessage(message.chat.id, 'It\'s currently ' .. jdat.currently.temperature .. units .. ' (feels like ' .. jdat.currently.apparentTemperature .. units .. ') in ' .. address .. '. ' .. jdat.daily.summary, nil, true, false, message.message_id)
end

return weather