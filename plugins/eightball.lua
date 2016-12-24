local eightball = {}
local mattata = require('mattata')

function eightball:init(configuration)
	eightball.arguments = 'eightball'
	eightball.commands = mattata.commands(self.info.username, configuration.commandPrefix, {'[Yy]/[Nn]%p*$'}):command('eightball').table
	eightball.help = configuration.commandPrefix .. 'eightball - Returns your destined decision through mattata\'s sixth sense.'
end

function eightball:onMessage(message, configuration)
	local answers = configuration.eightball.answers
	local yesNoAnswers = configuration.eightball.yesNoAnswers
	local output
	if message.text_lower:match('y/n%p?$') then output = yesNoAnswers[math.random(#yesNoAnswers)] else output = answers[math.random(#answers)] end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return eightball