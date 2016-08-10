local fortune = {}

local utilities = require('mattata.utilities')

fortune.command = 'fortune'
fortune.doc = 'Returns your fortune via mattata\'s sixth sense.'

function fortune:init(config)
	fortune.triggers = utilities.triggers(self.info.username, config.cmd_pat,
		{'[Yy]/[Nn]%p*$'}):t('fortune', true).table
end

local fortune_answers = {
	"It is certain.",
	"It has been confirmed.",
	"Without any doubts.",
	"Yes, definitely.",
	"You may rely on it.",
	"As I see it, yes.",
	"Most likely.",
	"Outlook: not so good.",
	"Yes.",
	"Signs point to yes.",
	"The reply is very weak, try again.",
	"Ask again later.",
	"I can not tell you right now.",
	"Cannot predict right now.",
	"Concentrate, and then ask again.",
	"Do not count on it.",
	"My reply is no.",
	"My sources say possibly.",
	"Outlook: very good.",
	"Very doubtful.",
	"Rowan's voice echoes: There is a time and place for everything, but not now."
}

local yesno_answers = {
	'Absolutely.',
	'In your dreams.',
	'Yes.',
	'No.'
}

function fortune:action(msg)

	local output

	if msg.text_lower:match('y/n%p?$') then
		output = yesno_answers[math.random(#yesno_answers)]
	else
		output = fortune_answers[math.random(#fortune_answers)]
	end

	utilities.send_reply(self, msg, output)

end

return fortune
