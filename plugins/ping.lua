local ping = {}
local mattata = require('mattata')

function ping:init(configuration)
	ping.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ping'):c('pong').table
end

function ping:onMessageReceive(message, configuration)
	mattata.sendMessage(message.chat.id, 'Pong!', nil, true, false, message.message_id, nil)
end

return ping