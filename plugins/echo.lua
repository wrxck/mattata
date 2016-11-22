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

function echo:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, echo.help, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, input, nil, true, false, channel_post.message_id)
end

function echo:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, echo.help, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, input, nil, true, false, message.message_id)
end

return echo