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

function shorten.getKeyboard()
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = 'goo.gl', callback_data = 'shorten:googl' },
		{ text = 'adf.ly', callback_data = 'shorten:adfly' }
	}}
	return keyboard
end

function shorten.googl(input)
	local configuration = require('configuration')
	local body = json.encode({ longUrl = tostring(input) })
	local response = {}
	local _, res = https.request({
		url = 'https://www.googleapis.com/urlshortener/v1/url?key=' .. configuration.keys.google,
		method = 'POST',
		headers = { ['Content-Type'] = 'application/json', ['Content-Length'] = body:len() },
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	})
	if res ~= 200 then return false end
	local jdat = json.decode(table.concat(response))
	if not jdat.id then return false end
	return jdat.id
end

function shorten.adfly(input)
	local configuration = require('configuration')
	local body = '_api_key=' .. configuration.keys.adfly.apikey .. '&_user_id=' .. configuration.keys.adfly.userid .. '&domain=adf.ly&url=' .. input .. '&advert_type=1'
	local response = {}
	local _, res = https.request({
		url = 'https://api.adf.ly/v1/shorten',
		method = 'POST',
		headers = {
			['Content-Type'] = 'application/x-www-form-urlencoded',
			['Content-Length'] = body:len()
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	})
	if res ~= 200 then return false end
	local jdat = json.decode(table.concat(response))
	if not jdat.data[1] then return false end
	return jdat.data[1].short_url
end
	
function shorten:onCallbackQuery(callback_query, message, configuration)
	local input = mattata.input(message.reply_to_message.text)
	if not input then return false end
	local keyboard = shorten.getKeyboard()
	local output
	if callback_query.data == 'googl' then
		output = shorten.googl(input)
	elseif callback_query.data == 'adfly' then
		output = shorten.adfly(input)
	end
	if not output then mattata.answerCallbackQuery(callback_query.id, 'An error occured. Either the API for shortening the URLs is down, or you entered an invalid URL.', true) return end
	mattata.editMessageText(message.chat.id, message.message_id, output, nil, true, json.encode(keyboard))
end

function shorten:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, shorten.help, nil, true, false, message.message_id) return end
	local keyboard = shorten.getKeyboard()
	mattata.sendMessage(message.chat.id, 'Select a URL shortening service using the buttons below:', nil, true, false, message.message_id, json.encode(keyboard))
end

return shorten