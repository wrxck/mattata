local eightball = {}
local functions = require('functions')
function eightball:init(configuration)
	eightball.command = 'eightball'
	eightball.triggers = functions.triggers(self.info.username, configuration.command_prefix, {'[Yy]/[Nn]%p*$'}):t('eightball', true).table
	eightball.documentation = configuration.command_prefix .. 'eightball - Returns your destined decision through mattata\'s sixth sense.'
end
function eightball:action(msg, configuration)
	local answers = configuration.eightball.answers
	local yes_no_answers = configuration.eightball.yes_no_answers
	local output = ''
	if msg.text_lower:match('y/n%p?$') then
		output = yes_no_answers[math.random(#yes_no_answers)]
	else
		output = answers[math.random(#answers)]
	end
	functions.send_reply(msg, output)
end
return eightball