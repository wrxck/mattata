local unban = {}
local functions = require('functions')
function unban:init(configuration)
	unban.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('unban', true).table
end
function unban:action(msg, configuration)
	if msg.from.id == configuration.owner_id then
		if msg.reply_to_message then
			functions.send_reply(msg, msg.reply_to_message.from.first_name .. ' has been unbanned!')
			functions.unban_chat_member(msg.chat.id, msg.reply_to_message.from.id)
			return
		else
			functions.send_reply(msg, '`Please reply to a message sent by the user you\'d like to unban.`', true)
			return
		end
	else
		return
	end
end
return unban