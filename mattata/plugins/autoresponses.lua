local autoresponses = {}

local utilities = require('mattata.utilities')

function autoresponses:init(config)
	config.autoresponses = config.autoresponses or {
		['Hello, #NAME.'] = {
			'hello',
			'hey',
			'sup',
			'hi',
			'good morning',
			'good day',
			'good afternoon',
			'good evening'
		},
		['Goodbye, #NAME.'] = {
			'bye',
			'later',
			'see ya',
			'good night'
		},
		['Welcome back, #NAME.'] = {
			'i\'m home',
			'i\'m back'
		},
		['You\'re welcome, #NAME.'] = {
			'thanks',
			'thank you'
		},
		['I wouldn\'t even touch you with a barge-pole, #NAME.'] = {
			'fuck me'
		},
		['No, fuck YOU, #NAME.'] = {
			'fuck you'
		},
		['You\'re a dick, #NAME.'] = {
			'i don\'t like you',
			'i hate you'
		}
	}

	autoresponses.triggers = {
		self.info.first_name:lower() .. '%p*$'
	}
end

function autoresponses:action(msg, config)

	local nick = utilities.build_name(msg.from.first_name, msg.from.last_name)
	if self.database.userdata[tostring(msg.from.id)] then
		nick = self.database.userdata[tostring(msg.from.id)].nickname or nick
	end

	for trigger,responses in pairs(config.autoresponses) do
		for _,response in pairs(responses) do
			if msg.text_lower:match(response..',? '..self.info.first_name:lower()) then
				local output = utilities.char.zwnj .. trigger:gsub('#NAME', nick)
				utilities.send_message(self, msg.chat.id, output)
				return
			end
		end
	end

	return true

end

return autoresponses
