local echo = {}
local mattata = require('mattata')

function echo:init(configuration)
	echo.arguments = 'echo <text>'
	echo.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('echo').table
	echo.help = configuration.commandPrefix .. 'echo <text> - Repeats a string of text.'
end

function echo:onMessage(message)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, echo.help, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, input, nil, true, false, message.message_id)
end

return echo