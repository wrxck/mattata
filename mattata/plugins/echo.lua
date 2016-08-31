local echo = {}
local functions = require('mattata.functions')
function echo:init(configuration)
	echo.command = 'echo <text>'
	echo.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('echo', true).table
	echo.doc = configuration.command_prefix .. 'echo <text> \nRepeats a string of text.'
end
function echo:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_message(self, msg.chat.id, echo.doc, true, msg.message_id, true)
	else
		local output
		if msg.chat.type == 'supergroup' then
			output = '*' .. functions.md_escape(input) .. '*'
		else
			output = functions.md_escape(functions.char.zwnj..input)
		end
		functions.send_message(self, msg.chat.id, output, true, nil, true)
	end
end
return echo
