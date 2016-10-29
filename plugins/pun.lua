local pun = {}
local mattata = require('mattata')

function pun:init(configuration)
	pun.arguments = 'pun'
	pun.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pun').table
	pun.help = configuration.commandPrefix .. 'pun - Generates a random pun.'
end

function pun:onMessageReceive(msg, configuration)
	local puns = configuration.puns
	mattata.sendMessage(msg.chat.id, puns[math.random(#puns)], 'Markdown', true, false, msg.message_id, nil)
end

return pun