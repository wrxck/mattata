local leavechat = {}
local functions = require('functions')
function leavechat:init(configuration)
	leavechat.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('leavechat', true).table
end
function leavechat:action(msg, configuration)
	local input = functions.input(msg.text)
	if input then
		if msg.from.id == configuration.owner_id then
			functions.send_message(input, '`Bye.`', true, nil, true)
			functions.leave_chat(input)
			return
		end	
	else
		if msg.from.id == configuration.owner_id then
			if msg.chat.type ~= 'private' then
				functions.send_reply(msg, '`Bye.`', true)
				functions.leave_chat(msg.chat.id)
				return
			else
				functions.send_reply(msg, '`You can\'t force me to leave a private chat with you...`', true)
				return
			end
		end
	end
end
return leavechat