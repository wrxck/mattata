local echo = {}
local functions = require('functions')
function echo:init(configuration)
	echo.command = 'echo <text>'
	echo.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('echo', true).table
	echo.documentation = configuration.command_prefix .. 'echo <text> - Repeats a string of text.'
end
function echo:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, echo.documentation)
		return
	end
	functions.send_reply(msg, input)
end
return echo