local canitrust = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function canitrust:init(configuration)
	canitrust.command = 'canitrust <URL>'
	canitrust.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('canitrust', true).table
	canitrust.documentation = configuration.command_prefix .. 'canitrust <URL> - Tells you of any known security issues with a website.'
end
function canitrust.validate(url)
	local parsed_url = URL.parse(url, { scheme = 'http', authority = '' })
	if not parsed_url.host and parsed_url.path then
		parsed_url.host = parsed_url.path
		parsed_url.path = ''
	end
	local url = URL.build(parsed_url)
	local protocol
	if parsed_url.scheme == 'http' then
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
function canitrust:action(msg, configuration)
	local input = functions.input(msg.text)
	if input then
		input = input:gsub('https', 'http'):gsub('HTTPS', 'https'):gsub('HTTP', 'http'):gsub('www.', '')
		local jstr = HTTPS.request(configuration.apis.canitrust .. URL.escape(input) .. '/&callback=process&key=' .. configuration.keys.canitrust)
		local jdat = JSON.decode(jstr)
		local output = ''
		if not canitrust.validate(input) then
			output = 'Invalid URL.'
		end
		if jstr == 'process({ "' .. input .. '": { "target": "' .. input .. '" } } )' and canitrust.validate(input) then
			output = 'There are *no known issues* with this website.'
		end
		if string.match(jstr, '"101"') then
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
		if output ~= 'Invalid URL.' then
			functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"' .. 'Proceed to site' .. '", "url":"' .. input .. '"}]]}')
			return
		else
			functions.send_reply(msg, output, true)
			return
		end
	else
		functions.send_reply(msg, canitrust.documentation)
		return
	end
end
return canitrust