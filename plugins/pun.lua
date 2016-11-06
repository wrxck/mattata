--[[

    Based on pun.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local pun = {}
local mattata = require('mattata')

function pun:init(configuration)
	pun.arguments = 'pun'
	pun.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pun').table
	pun.help = configuration.commandPrefix .. 'pun - Generates a random pun.'
end

function pun:onMessageReceive(message, configuration)
	local puns = configuration.puns
	mattata.sendMessage(message.chat.id, puns[math.random(#puns)], 'Markdown', true, false, message.message_id, nil)
end

return pun