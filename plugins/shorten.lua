local shorten = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function shorten:init(configuration)
	shorten.arguments = 'shorten <URL>'
	shorten.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('shorten').table
	shorten.help = configuration.commandPrefix .. 'shorten - Shortens the given URL.'
end

function shorten:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, shorten.help, nil, true, false, message.message_id, nil)
		return
	end
	local jstr, res = HTTP.request(configuration.apis.shorten .. input)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	if string.match(jstr, 'Invalid URL') then
		mattata.sendMessage(message.chat.id, 'Invalid URL', nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.short, nil, true, false, message.message_id, nil)
end

return shorten