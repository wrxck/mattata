local location = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local setloc = require('plugins.setloc')

function location:init(configuration)
	location.arguments = 'location <query>'
	location.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('location').table
	location.inlineCommands = location.commands
	location.help = configuration.commandPrefix .. 'location <query> - Sends a location from Google Maps.'
end

function location:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input))
	if res ~= 200 then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.connection,
			input_message_content = { message_text = language.errors.connection }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = json.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.results,
			input_message_content = { message_text = language.errors.results }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local results = json.encode({{
		type = 'location',
		id = '1',
		latitude = jdat.results[1].geometry.location.lat,
		longitude = jdat.results[1].geometry.location.lng,
		title = input
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function location:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then
		local location = setloc.getLocation(message.from)
		if not location then mattata.sendMessage(message.chat.id, 'You don\'t have a location set. Use \'' .. configuration.commandPrefix .. 'setloc <location>\' to set one.', nil, true, false, message.message_id); return end
		mattata.sendLocation(message.chat.id, json.decode(location).latitude, json.decode(location).longitude)
		return
	end
	local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	local jdat = json.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id); return end
	mattata.sendLocation(message.chat.id, jdat.results[1].geometry.location.lat, jdat.results[1].geometry.location.lng)
end

return location