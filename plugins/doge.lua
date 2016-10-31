local doge = {}
local mattata = require('mattata')
local URL = require('socket.url')

function doge:init(configuration)
	doge.arguments = 'doge <text>'
	doge.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('doge').table
	doge.help = configuration.commandPrefix .. 'doge <text> - Doge-ifies the given text. It doesn\'t like emoji!'
end

function doge:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, doge.help, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendPhoto(msg.chat.id, 'http://dogr.io/' .. input:gsub(' ', ''):gsub('\n', '/') .. '.png')
end

return doge

