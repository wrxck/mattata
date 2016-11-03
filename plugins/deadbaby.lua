local deadbaby = {}
local mattata = require('mattata')

function deadbaby:init(configuration)
	deadbaby.arguments = 'deadbaby'
	deadbaby.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('deadbaby').table
	deadbaby.help = configuration.commandPrefix .. 'deadbaby - Generates a random dead baby joke.'
end

function deadbaby:onMessageReceive(message, configuration)
	local deadbabyjokes = configuration.deadbabyjokes
	mattata.sendMessage(message.chat.id, deadbabyjokes[math.random(#deadbabyjokes)], 'Markdown', true, false, message.message_id, nil)
end

return deadbaby