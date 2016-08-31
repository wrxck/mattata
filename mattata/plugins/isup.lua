-- created by wrxck
local functions = require('mattata.functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local isup = {}
function isup:init(configuration)
	isup.command = configuration.command_prefix .. 'isup <URL>'
	isup.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('isdown', true):t('isup', true).table
	isup.doc = 'Check if the specified URL is down for everyone or just you.'
end
function isup.website_down_http(url)
	local parsed_url = URL.parse(url,	{ scheme = 'http', authority = '' })
	if not parsed_url.host and parsed_url.path then
		parsed_url.host = parsed_url.path
		parsed_url.path = ''
	end
	local url = URL.build(parsed_url)
	local protocol
		if parsed_url.scheme == 'https' then
			protocol = HTTPS
		else
			protocol = HTTP
	end
	local options =	{
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
function isup:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, isup.doc, true)
		return
	end
	if isup.website_down_http(input) then
		functions.send_reply(self, msg, 'This website is up, maybe it\'s just you?')
	else
		functions.send_reply(self, msg, 'It\'s not just you, this website is down!')
	end
end
return isup
