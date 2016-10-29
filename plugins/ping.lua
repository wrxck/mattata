local ping = {}
local mattata = require('mattata')

function ping:init(configuration)
	ping.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ping'):c('pong').table
end

function ping:onMessageReceive(msg, configuration)
	mattata.sendMessage(msg.chat.id, 'Pong!', nil, true, false, msg.message_id, nil)
end

return ping