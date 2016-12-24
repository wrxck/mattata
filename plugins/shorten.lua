local shorten = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

function shorten:init(configuration)
	shorten.arguments = 'shorten <url>'
	shorten.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('shorten').table
	shorten.help = configuration.commandPrefix .. 'shorten - Shortens the given url using Google url Shortener.'
end

function shorten:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, shorten.help, nil, true, false, message.message_id); return end
	local body = json.encode({ longUrl = tostring(input) })
	local response = {}
	local _, res = https.request({
		url = 'https://www.googleapis.com/urlshortener/v1/url?key=' .. configuration.keys.google,
		method = 'POST',
		headers = { ['Content-Type'] = 'application/json', ['Content-Length'] = body:len() },
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	})
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	local jdat = json.decode(table.concat(response))
	mattata.sendMessage(message.chat.id, jdat.id, nil, true, false, message.message_id)
end

return shorten