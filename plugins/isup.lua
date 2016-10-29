local isup = {}
local mattata = require('mattata')
local URL = require('socket.url')
local HTTP = require('socket.http')

function isup:init(configuration)
	isup.arguments = 'isup <URL>'
	isup.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('isup').table
	isup.help = configuration.commandPrefix .. 'isup <URL> - Check if the specified URL is down for everyone or just you.'
end

function isup.isWebsiteDown(url)
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

function isup:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, isup.help, nil, true, false, msg.message_id, nil)
		return
	end
	if isup.isWebsiteDown(input) then
		mattata.sendMessage(msg.chat.id, 'This website is up, maybe it\'s just you?', nil, true, false, msg.message_id, nil)
	else
		mattata.sendMessage(msg.chat.id, 'It\'s not just you, this website is down!', nil, true, false, msg.message_id, nil)
	end
end

return isup