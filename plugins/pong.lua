local pong = {}
local functions = require('functions')
function pong:init(configuration)
	pong.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pong', true).table
end
function pong:action(msg, configuration)
	local output = msg.text:match('^' .. configuration.command_prefix .. 'pong') and 'gtfo xD'
	functions.send_reply(msg, output)
end
return pong