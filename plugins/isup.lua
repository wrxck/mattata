local isup = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function isup:init(configuration)
	isup.arguments = 'isup <url>'
	isup.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('isup').table
	isup.help = configuration.commandPrefix .. 'isup <url> - Check if the specified url is down for everyone or just you.'
end

function isup.isWebsiteDown(input)
	local protocol = http
	if input:lower():match('^https') then protocol = https elseif not input:lower():match('^http') then input = 'http://' .. input end
	local _, code = protocol.request(input)
	code = tonumber(code)
	if not code or code > 399 then return false end
	return true
end

function isup:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, isup.help, nil, true, false, message.message_id)
		return
	end
	if isup.isWebsiteDown(input) then
		mattata.sendMessage(message.chat.id, 'This website is up, maybe it\'s just you?', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'It\'s not just you, this website is down!', nil, true, false, message.message_id)
end

return isup