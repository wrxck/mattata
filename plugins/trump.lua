local trump = {}
local mattata = require('mattata')

function trump:init(configuration)
	trump.arguments = 'trump <target>'
	trump.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('trump').table
	trump.help = configuration.commandPrefix .. 'trump <target> - Trump somebody (or something). If no target is given then, well, you ARE the target!'
end

function trump:onMessageReceive(message, configuration)
	local trumps = configuration.trumps
	local input = mattata.input(message.text)
	local victim
	if not input then
		victim = message.from.first_name
	else
		if message.reply_to_message then
			victim = message.reply_to_message.from.first_name
		else
			victim = input
		end
	end
	mattata.sendMessage(message.chat.id, trumps[math.random(#trumps)]:gsub('VICTIM', victim) .. ' - Donald J. Trump', nil, true, false, message.message_id, nil)
end

return trump
