local canitrust = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function canitrust:init(configuration)
	canitrust.arguments = 'canitrust <URL>'
	canitrust.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('canitrust').table
	canitrust.help = configuration.commandPrefix .. 'canitrust <URL> - Tells you of any known security issues with a website.'
end

function canitrust.validate(url)
	local parsedUrl = URL.parse(url, { scheme = 'http', authority = '' })
	if not parsedUrl.host and parsedUrl.path then
		parsedUrl.host = parsedUrl.path
		parsedUrl.path = ''
	end
	local url = URL.build(parsedUrl)
	local protocol
	if parsedUrl.scheme == 'http' then
		protocol = HTTP
	end
	local options = {
		url = url,
		redirect = false,
		method = 'GET'
	}
	local _, code = protocol.request(options)
	code = tonumber(code)
	if not code or code >= 400 then
		return false
	end
	return true
end

function canitrust:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text_lower)
	if not input then
		mattata.sendMessage(channel_post.chat.id, canitrust.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr = HTTPS.request('https://api.mywot.com/0.4/public_link_json2?hosts=' .. URL.escape(input) .. '/&callback=process&key=' .. configuration.keys.canitrust)
	local jdat = JSON.decode(jstr)
	local output = ''
	if not canitrust.validate(input) then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	if jstr:match('^process%({ "' .. input .. '": { "target": "' .. input .. '" } } %)$') then
		output = 'There are *no known issues* with this website.'
	elseif string.match(jstr, '"101"') then
		output = 'This website is likely to contain *malware*.'
	elseif string.match(jstr, '"102"') then
		output = 'This website is likely to provide a *poor customer experience*.'
	elseif string.match(jstr, '"103"') then
		output = 'This website has been flagged as *phishing*.'
	elseif string.match(jstr, '"104"') then
		output = 'This website has been flagged as *a scam*.'
	elseif string.match(jstr, '"105"') then
		output = 'This website is *potentially illegal*.'
	elseif string.match(jstr, '"201"') then
		output = 'This website is known to be *unethical*, and may provide *misleading claims*.'
	elseif string.match(jstr, '"202"') then
		output = 'This website has been flagged as a *privacy risk*.'
	elseif string.match(jstr, '"203"') then
		output = 'This website is *suspicious*.'
	elseif string.match(jstr, '"204"') then
		output = 'This website has been flagged for containing *hate/discrimination*.'
	elseif string.match(jstr, '"205"') then
		output = 'This website has been flagged as *spam*.'
	elseif string.match(jstr, '"206"') then
		output = 'This website has been known to distribute *potentially unwanted programs*.'
	elseif string.match(jstr, '"207"') then
		output = 'This website contains *ads/pop-ups*.'
	elseif string.match(jstr, '"301"') then
		output = 'This website is known to *track your online activity*.'
	elseif string.match(jstr, '"302"') then
		output = 'This website has been associated with *alternative or controversial medicine*.'
	elseif string.match(jstr, '"303"') then
		output = 'This website is likely to contain *religious/political beliefs*.'
	elseif string.match(jstr, '"401"') then
		output = 'This website contains *adult content*.'
	elseif string.match(jstr, '"402"') then
		output = 'This website contains *incidental nudity*.'
	elseif string.match(jstr, '"403"') then
		output = 'This website has been flagged as *gruesome or shocking*.'
	elseif string.match(jstr, '"404"') then
		output = 'This website is *suitable for kids*.'
	elseif string.match(jstr, '"501"') then
		output = 'There are *no known issues* with this website.'
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Proceed to site',
				url = input
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function canitrust:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then
		mattata.sendMessage(message.chat.id, canitrust.help, nil, true, false, message.message_id)
		return
	end
	local jstr = HTTPS.request('https://api.mywot.com/0.4/public_link_json2?hosts=' .. URL.escape(input) .. '/&callback=process&key=' .. configuration.keys.canitrust)
	local jdat = JSON.decode(jstr)
	local output = ''
	if not canitrust.validate(input) then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	if jstr:match('^process%({ "' .. input .. '": { "target": "' .. input .. '" } } %)$') then
		output = 'There are *no known issues* with this website.'
	elseif string.match(jstr, '"101"') then
		output = 'This website is likely to contain *malware*.'
	elseif string.match(jstr, '"102"') then
		output = 'This website is likely to provide a *poor customer experience*.'
	elseif string.match(jstr, '"103"') then
		output = 'This website has been flagged as *phishing*.'
	elseif string.match(jstr, '"104"') then
		output = 'This website has been flagged as *a scam*.'
	elseif string.match(jstr, '"105"') then
		output = 'This website is *potentially illegal*.'
	elseif string.match(jstr, '"201"') then
		output = 'This website is known to be *unethical*, and may provide *misleading claims*.'
	elseif string.match(jstr, '"202"') then
		output = 'This website has been flagged as a *privacy risk*.'
	elseif string.match(jstr, '"203"') then
		output = 'This website is *suspicious*.'
	elseif string.match(jstr, '"204"') then
		output = 'This website has been flagged for containing *hate/discrimination*.'
	elseif string.match(jstr, '"205"') then
		output = 'This website has been flagged as *spam*.'
	elseif string.match(jstr, '"206"') then
		output = 'This website has been known to distribute *potentially unwanted programs*.'
	elseif string.match(jstr, '"207"') then
		output = 'This website contains *ads/pop-ups*.'
	elseif string.match(jstr, '"301"') then
		output = 'This website is known to *track your online activity*.'
	elseif string.match(jstr, '"302"') then
		output = 'This website has been associated with *alternative or controversial medicine*.'
	elseif string.match(jstr, '"303"') then
		output = 'This website is likely to contain *religious/political beliefs*.'
	elseif string.match(jstr, '"401"') then
		output = 'This website contains *adult content*.'
	elseif string.match(jstr, '"402"') then
		output = 'This website contains *incidental nudity*.'
	elseif string.match(jstr, '"403"') then
		output = 'This website has been flagged as *gruesome or shocking*.'
	elseif string.match(jstr, '"404"') then
		output = 'This website is *suitable for kids*.'
	elseif string.match(jstr, '"501"') then
		output = 'There are *no known issues* with this website.'
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Proceed to site',
				url = input
			}
		}
	}
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return canitrust