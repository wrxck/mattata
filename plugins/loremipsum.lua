local loremipsum = {}
local mattata = require('mattata')
local HTTP = require('socket.http')

function loremipsum:init(configuration)
	loremipsum.arguments = 'loremipsum'
	loremipsum.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('loremipsum').table
	loremipsum.help = configuration.commandPrefix .. 'loremipsum - Generates a few Lorem Ipsum sentences!'
end

function loremipsum:onMessageReceive(message, language)
	local str, res = HTTP.request('http://loripsum.net/api/1/medium/plaintext')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, str, nil, true, false, message.message_id)
end

return loremipsum