--[[

    Based on echo.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local echo = {}
local mattata = require('mattata')

function echo:init(configuration)
	echo.arguments = 'echo <text>'
	echo.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('echo').table
	echo.help = configuration.commandPrefix .. 'echo <text> - Repeats a string of text.'
end

function echo:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, echo.help, nil, true, false, message.message_id, nil)
		return
	end
	mattata.sendMessage(message.chat.id, input, nil, true, false, message.message_id, nil)
end

return echo