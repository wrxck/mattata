local canitrust = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function canitrust:init(configuration)
	assert(configuration.keys.canitrust, 'canitrust.lua requires an API key, and you haven\'t got one configured!')
	canitrust.arguments = 'canitrust <url>'
	canitrust.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('canitrust').table
	canitrust.help = configuration.commandPrefix .. 'canitrust <url> - Tells you of any known security issues with a website.'
end

function canitrust.validate(url)
	local parsedUrl = url.parse(url, { scheme = 'http', authority = '' })
	if not parsedUrl.host and parsedUrl.path then parsedUrl.host = parsedUrl.path; parsedUrl.path = '' end
	local url = url.build(parsedUrl)
	local protocol
	if parsedUrl.scheme == 'http' then protocol = http end
	local options = { url = url, redirect = false, method = 'GET' }
	local _, code = protocol.request(options)
	code = tonumber(code)
	if not code or code >= 400 then return false end
	return true
end

function canitrust:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, canitrust.help, nil, true, false, message.message_id) return end
	local jstr = https.request('https://api.mywot.com/0.4/public_link_json2?hosts=' .. url.escape(input) .. '&callback=process&key=' .. configuration.keys.canitrust)
	local jdat = json.decode(jstr)
	local output = ''
	if not canitrust.validate(input) then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	if jstr:match('^process%({ "' .. input .. '": { "target": "' .. input .. '" } } %)$') then
		output = 'There are *no known issues* with this website.'
	elseif jstr:match('"101"') then
		output = 'This website is likely to contain *malware*.'
	elseif jstr:match('"102"') then
		output = 'This website is likely to provide a *poor customer experience*.'
	elseif jstr:match('"103"') then
		output = 'This website has been flagged as *phishing*.'
	elseif jstr:match('"104"') then
		output = 'This website has been flagged as *a scam*.'
	elseif jstr:match('"105"') then
		output = 'This website is *potentially illegal*.'
	elseif jstr:match('"201"') then
		output = 'This website is known to be *unethical*, and may provide *misleading claims*.'
	elseif jstr:match('"202"') then
		output = 'This website has been flagged as a *privacy risk*.'
	elseif jstr:match('"203"') then
		output = 'This website is *suspicious*.'
	elseif jstr:match('"204"') then
		output = 'This website has been flagged for containing *hate/discrimination*.'
	elseif jstr:match('"205"') then
		output = 'This website has been flagged as *spam*.'
	elseif jstr:match('"206"') then
		output = 'This website has been known to distribute *potentially unwanted programs*.'
	elseif jstr:match('"207"') then
		output = 'This website contains *ads/pop-ups*.'
	elseif jstr:match('"301"') then
		output = 'This website is known to *track your online activity*.'
	elseif jstr:match('"302"') then
		output = 'This website has been associated with *alternative or controversial medicine*.'
	elseif jstr:match('"303"') then
		output = 'This website is likely to contain *religious/political beliefs*.'
	elseif jstr:match('"401"') then
		output = 'This website contains *adult content*.'
	elseif jstr:match('"402"') then
		output = 'This website contains *incidental nudity*.'
	elseif jstr:match('"403"') then
		output = 'This website has been flagged as *gruesome or shocking*.'
	elseif jstr:match('"404"') then
		output = 'This website is *suitable for kids*.'
	elseif jstr:match('"501"') then
		output = 'There are *no known issues* with this website.'
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Proceed To Site', url = input }}}
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, json.encode(keyboard))
end

return canitrust