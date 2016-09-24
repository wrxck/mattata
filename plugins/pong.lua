local pong = {}
local functions = require('functions')
function pong:init(configuration)
	pong.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pong').table
end
function pong:action(msg, configuration)
	local output = msg.text_lower:match('^' .. configuration.command_prefix .. 'pong') and '*gtfo xd*'
	functions.send_reply(msg, output, true)
end
return pong