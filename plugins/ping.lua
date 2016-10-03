local ping = {}
local functions = require('functions')
function ping:init(configuration)
	ping.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ping', true):t('pong', true).table
end
function ping:action(msg, configuration)
	functions.send_reply(msg, 'Pong!')
end
return ping