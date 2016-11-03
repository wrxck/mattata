local eightball = {}
local mattata = require('mattata')

function eightball:init(configuration)
	eightball.arguments = 'eightball'
	eightball.commands = mattata.commands(self.info.username, configuration.commandPrefix, {'[Yy]/[Nn]%p*$'}):c('eightball').table
	eightball.help = configuration.commandPrefix .. 'eightball - Returns your destined decision through mattata\'s sixth sense.'
end

function eightball:onMessageReceive(message, configuration)
	local answers = configuration.eightball.answers
	local yes_no_answers = configuration.eightball.yes_no_answers
	local output = ''
	if message.text_lower:match('y/n%p?$') then
		output = yes_no_answers[math.random(#yes_no_answers)]
	else
		output = answers[math.random(#answers)]
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
end

return eightball