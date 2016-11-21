local weather = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function weather:init(configuration)
	weather.arguments = 'weather <location>'
	weather.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('weather').table
	weather.help = configuration.commandPrefix .. 'weather <location> - Sends the current weather for the given location.'
end

function weather:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, weather.help, nil, true, false, channel_post.message_id)
		return
	end
	local url = 'http://api.openweathermap.org/data/2.5/weather?q=' .. URL.escape(input) .. '&units=metric&lang=' .. configuration.language .. '&apikey=' .. configuration.keys.weather
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	if jstr == '{"cod":"502","message":"Error: Not found city"}' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*Weather in ' .. jdat.name .. ':*\n'
	if jdat.main.temp then
		output = output .. 'Temparature: ' .. jdat.main.temp .. ' °C\n'
	elseif jdat.main.pressure then
		output = output .. 'Pressure: ' .. jdat.main.pressure .. '\n'
	elseif jdat.main.humidity then
		output = output .. 'Humidity: ' .. jdat.main.humidity
	end
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id)
end

function weather:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, weather.help, nil, true, false, message.message_id)
		return
	end
	local url = 'http://api.openweathermap.org/data/2.5/weather?q=' .. URL.escape(input) .. '&units=metric&lang=' .. language.locale .. '&apikey=' .. configuration.keys.weather
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	if jstr == '{"cod":"502","message":"Error: Not found city"}' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*Weather in ' .. jdat.name .. ':*\n'
	if jdat.main.temp then
		output = output .. 'Temparature: ' .. jdat.main.temp .. ' °C\n'
	elseif jdat.main.pressure then
		output = output .. 'Pressure: ' .. jdat.main.pressure .. '\n'
	elseif jdat.main.humidity then
		output = output .. 'Humidity: ' .. jdat.main.humidity
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return weather