local chatinfo = {}
local functions = require('functions')
function chatinfo:init(configuration)
	chatinfo.command = 'chatinfo'
	chatinfo.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('chatinfo', true).table
end
function chatinfo:action(msg)
	local output = ''
	if msg.chat.type ~= 'private' then
		output = 'You are speaking in the ' .. msg.chat.type .. ' *' .. msg.chat.title .. '*. ' .. 'The ID is `' .. msg.chat.id .. '`.'
		functions.send_reply(msg, output, true)
		return
	else
		output = 'Hello, *' .. functions.get_name(msg) .. '*. Your ID is `' .. msg.from.id .. '`.'
		functions.send_reply(msg, output, true)
		return
	end
end
return chatinfo