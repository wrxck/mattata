local echo = {}
local mattata = require('mattata')

function echo:init(configuration)
	echo.arguments = 'echo <text>'
	echo.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('echo').table
	echo.help = configuration.commandPrefix .. 'echo <text> - Repeats a string of text.'
end

function echo:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, echo.help, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendMessage(msg.chat.id, input, nil, true, false, msg.message_id, nil)
end

return echo