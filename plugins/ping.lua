local ping = {}
local mattata = require('mattata')

function ping:init(configuration) ping.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('ping'):command('pong').table end

function ping:onMessage(message) mattata.sendMessage(message.chat.id, 'Pong!', nil, true, false, message.message_id) end

return ping