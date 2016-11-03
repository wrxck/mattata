local slap = {}
local mattata = require('mattata')

function slap:init(configuration)
	slap.arguments = 'slap <target>'
	slap.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('slap').table
	slap.help = configuration.commandPrefix .. 'slap <target> - Slap somebody (or something).'
end

function slap:onMessageReceive(message, configuration)
	local slaps = configuration.slaps
	local input = mattata.input(message.text)
	local victor = message.from.first_name
	local victim
	if not input then
		victor = self.info.first_name
		victim = message.from.first_name
	else
		if message.reply_to_message then
			victim = message.reply_to_message.from.first_name
		else
			victim = input
		end
	end
	mattata.sendMessage(message.chat.id, slaps[math.random(#slaps)]:gsub('VICTIM', victim):gsub('VICTOR', victor), nil, true, false, message.message_id, nil)
end

return slap