local ping = {}
local functions = require('functions')
function ping:init(configuration)
 ping.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ping').table
end
function ping:action(msg, configuration)
 local output = msg.text_lower:match('^'..configuration.command_prefix..'ping') and 'Pong!'
 functions.send_reply(self, msg, output)
end
return ping