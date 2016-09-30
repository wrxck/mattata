local ping = {}
local functions = require('functions')
function ping:init(configuration)
	ping.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ping', true).table
end
function ping:action(msg, configuration)
	local output = msg.text:match('^' .. configuration.command_prefix .. 'ping') and 'Pong!'
	functions.send_reply(msg, output)
end
return ping