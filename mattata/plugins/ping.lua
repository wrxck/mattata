local ping = {}
local functions = require('mattata.functions')
function ping:init(configuration)
	ping.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ping').table
end
function ping:action(msg, configuration)
	local output = msg.text_lower:match('^'..configuration.command_prefix..'ping') and 'Pong!'
	if msg.user.id == configuration.admin then
	    functions.send_reply(self, msg.chat.id, output)
	end
end
return ping
