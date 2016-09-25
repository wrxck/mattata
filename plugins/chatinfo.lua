local chatinfo = {}
local functions = require('functions')
function chatinfo:init(configuration)
	chatinfo.command = 'chatinfo'
	chatinfo.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('chatinfo', true).table
end
function chatinfo:action(msg)
	if msg.chat.type ~= 'private' then
		functions.send_reply(msg, msg.chat.title .. ' (' .. msg.chat.type .. ' | ' .. msg.chat.id .. ')', true)
		return
	else
		return
	end
end
return chatinfo