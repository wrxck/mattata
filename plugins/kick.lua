local kick = {}
local mattata = require('mattata')

function kick:init(configuration)
	kick.arguments = 'kick'
	kick.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('kick').table
	kick.help = configuration.commandPrefix .. 'kick - Kicks the replied-to user from the chat.'
end

function kick:onMessageReceive(message, configuration)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message then
					mattata.sendMessage(message.chat.id, kick.help, nil, true, false, message.message_id, nil)
					return
				end
				for _, admin in ipairs(admin_list.result) do
					if admin.user.id == message.reply_to_message.from.id then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id, nil)
						return
					end
				end
				if message.reply_to_message.from.id ~= self.info.id then
					local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.from.id)
					if not res then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id, nil)
						return
					else
						mattata.sendMessage(message.chat.id, 'Kicked ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id, nil)
						mattata.unbanChatMember(message.chat.id, message.reply_to_message.from.id)
						return
					end
				end
				if message.reply_to_message.forward_from then
					if message.reply_to_message.forward_from.id ~= self.info.id then
						local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.forward_from.id)
						if not res then
							mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id, nil)
							return
						else
							mattata.sendMessage(message.chat.id, 'Kicked ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id, nil)
							mattata.unbanChatMember(message.chat.id, message.reply_to_message.forward_from.id)
							return
						end
					end
				end
			end
		end
	end
end

return kick