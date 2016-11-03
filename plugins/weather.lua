local weather = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function weather:init(configuration)
	weather.arguments = 'weather <location>'
	weather.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('weather').table
	weather.help = configuration.commandPrefix .. 'weather <location> - Sends the current weather for the given location.'
end

function weather:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, weather.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.weather .. URL.escape(input) .. '&units=metric&lang=' .. configuration.language .. '&apikey=' .. configuration.keys.weather
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	if jstr == '{"cod":"502","message":"Error: Not found city"}' then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*Weather in ' .. jdat.name .. ':*\n'
	output = output .. 'Temparature: ' .. jdat.main.temp .. ' °C\n'
	output = output .. 'Pressure: ' .. jdat.main.pressure .. '\n'
	output = output .. 'Humidity: ' .. jdat.main.humidity
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
end

return weather