local istuesday = {}
local HTTP = require('dependencies.socket.http')
local mattata = require('mattata')

function istuesday:init(configuration)
	istuesday.arguments = 'istuesday'
	istuesday.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('istuesday', true):c('it', true).table
	istuesday.help = configuration.commandPrefix .. 'istuesday - Tells you if it\'s Tuesday or not. Alias: ' .. configuration.commandPrefix .. 'it.'
end

function istuesday:onMessageReceive(msg)
	local str, res = HTTP.request('http://www.studentology.net/tuesday')
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local output = ''
	if string.match(str, 'YES') then
		output = 'Yes!'
	else
		output = 'No.'
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return istuesday