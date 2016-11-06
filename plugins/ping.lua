--[[

    Based on ping.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local ping = {}
local mattata = require('mattata')

function ping:init(configuration)
	ping.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ping'):c('pong').table
end

function ping:onMessageReceive(message, configuration)
	mattata.sendMessage(message.chat.id, 'Pong!', nil, true, false, message.message_id, nil)
end

return ping