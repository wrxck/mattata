local canitrust = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function canitrust:init(configuration)
	canitrust.command = 'canitrust <URL>'
	canitrust.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('canitrust', true).table
	canitrust.doc = configuration.command_prefix .. 'canitrust <URL> - Tells you of any known security issues with a website.'
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
	else
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
		input = input:gsub('https', ''):gsub('http', ''):gsub('HTTPS', ''):gsub('HTTP', ''):gsub('www.', '')
		local jstr = HTTPS.request(configuration.canitrust_api .. input .. '/&callback=process&key=' .. configuration.canitrust_key)
		local jdat = JSON.decode(jstr)
		local output = '`' .. jstr .. '`'
		if not canitrust.validate(input) then
			output = '*This website has been flagged as:* `Invalid URL`'
		end
		if jstr == 'process({ "' .. input .. '": { "target": "' .. input .. '" } } )' and canitrust.validate(input) then
			output = '*This website has been flagged as:* `No issues known`'
		end
		if string.match(output, '"101"') then
			output = '*This website has been flagged as:* `Malware`'
		elseif string.match(output, '"102"') then
			output = '*This website has been flagged as:* `Poor customer experience`'
		elseif string.match(output, '"103"') then
			output = '*This website has been flagged as:* `Phishing`'
		elseif string.match(output, '"104"') then
			output = '*This website has been flagged as:* `Scam`'
		elseif string.match(output, '"105"') then
			output = '*This website has been flagged as:* `Potentially illegal`'
		elseif string.match(output, '"201"') then
			output = '*This website has been flagged as:* `Misleading claims or unethical`'
		elseif string.match(output, '"202"') then
			output = '*This website has been flagged as:* `Privacy risks`'
		elseif string.match(output, '"203"') then
			output = '*This website has been flagged as:* `Suspicious`'
		elseif string.match(output, '"204"') then
			output = '*This website has been flagged as:* `Hate, discrimination`'
		elseif string.match(output, '"205"') then
			output = '*This website has been flagged as:* `Spam`'
		elseif string.match(output, '"206"') then
			output = '*This website has been flagged as:* `Potentially unwanted programs`'
		elseif string.match(output, '"207"') then
			output = '*This website has been flagged as:* `Ads/pop-ups`'
		elseif string.match(output, '"301"') then
			output = '*This website has been flagged as:* `Online tracking`'
		elseif string.match(output, '"302"') then
			output = '*This website has been flagged as:* `Alternative or controversial medicine`'
		elseif string.match(output, '"303"') then
			output = '*This website has been flagged as:* `Opinions, religion, politics`'
		elseif string.match(output, '"303"') then
			output = '*This website has been flagged as:* `Other`'
		elseif string.match(output, '"401"') then
			output = '*This website has been flagged as:* `Adult content`'
		elseif string.match(output, '"402"') then
			output = '*This website has been flagged as:* `Incidental nudity`'
		elseif string.match(output, '"403"') then
			output = '*This website has been flagged as:* `Gruesome or shocking`'
		elseif string.match(output, '"404"') then
			output = '*This website has been flagged as:* `Site for kids`'
		elseif string.match(output, '"501"') then
			output = '*This website has been flagged as:* `No issues known`'
		end
		functions.send_reply(self, msg, output, true)
		return
	else
		functions.send_reply(self, msg, canitrust.doc, true)
		return
	end
end
return canitrust