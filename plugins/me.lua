local me = {}
local functions = require('functions')
function me:init(configuration)
	me.command = 'me'
	me.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('me', true).table
	me.doc = 'Perform an action! Markdown is supported.'
end
function me:action(msg, t)
	local name = functions.build_name(t.first_name, t.last_name)
	local input = msg.text
	local output = name .. input
	if input == '' then
		output = 'Please specify an action to perform.'
	end
	functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return me