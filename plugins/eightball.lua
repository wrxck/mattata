local eightball = {}
local functions = require('functions')
function eightball:init(configuration)
	eightball.command = 'eightball'
	eightball.doc = configuration.command_prefix .. 'eightball - Returns your destined decision through mattata\'s sixth sense.'
	eightball.triggers = functions.triggers(self.info.username, configuration.command_prefix, {'[Yy]/[Nn]%p*$'}):t('eightball', true).table
end
function eightball:action(msg, configuration)
	local eightball_answers = configuration.eightball_answers
	local eightball_yes_no_answers = configuration.eightball_yes_no_answers
	local output
	if msg.text_lower:match('y/n%p?$') then
		output = eightball_yes_no_answers[math.random(#eightball_yes_no_answers)]
	else
		output = eightball_answers[math.random(#eightball_answers)]
	end
	functions.send_reply(msg, '`' .. output .. '`', true)
end
return eightball