local unban = {}
local mattata = require('mattata')

function unban:init(configuration)
	unban.arguments = 'unban'
	unban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('unban').table
	unban.help = configuration.commandPrefix .. 'unban - Unbans the replied-to user from the chat.'
end

function unban:onMessageReceive(msg, configuration)
	if msg.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(msg.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == msg.from.id then
				if not msg.reply_to_message then
					mattata.sendMessage(msg.chat.id, unban.help, nil, true, false, msg.message_id, nil)
					return
				end
				if msg.reply_to_message.from.id ~= self.info.id then
					local res = mattata.unbanChatMember(msg.chat.id, msg.reply_to_message.from.id)
					if res then
						mattata.sendMessage(msg.chat.id, 'Unbanned ' .. msg.reply_to_message.from.first_name .. '.', nil, true, false, msg.message_id, nil)
						return
					end
				end
			end
		end
	end
end

return unban