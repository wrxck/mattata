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

function shorten:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, shorten.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTP.request(configuration.apis.shorten .. input)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	if string.match(jstr, 'Invalid URL') then
		mattata.sendMessage(msg.chat.id, 'Invalid URL', nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(msg.chat.id, jdat.short, nil, true, false, msg.message_id, nil)
end

return shorten