local echo = {}
local functions = require('functions')
function echo:init(configuration)
	echo.command = 'echo <text>'
	echo.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('echo', true).table
	echo.doc = configuration.command_prefix .. 'echo <text> - Repeats a string of text.'
end
function echo:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, echo.doc, true)
	else
		functions.send_reply(self, msg, input, true)
	end
end
return echo