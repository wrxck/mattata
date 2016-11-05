local ban = {}
local mattata = require('mattata')

function ban:init(configuration)
	ban.arguments = 'ban'
	ban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ban').table
	ban.help = configuration.commandPrefix .. 'ban - Bans the replied-to user from the chat.'
end

function ban:onMessageReceive(message, configuration)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message or message.reply_to_message.from.id == configuration.owner then
					mattata.sendMessage(message.chat.id, ban.help, nil, true, false, message.message_id)
					return
				end
				for _, admin in ipairs(admin_list.result) do
					if admin.user.id == message.reply_to_message.from.id then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
						return
					end
				end
				if message.reply_to_message.from.id ~= self.info.id then
					local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.from.id)
					if not res then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
						return
					else
						mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
						return
					end
				end
				if message.reply_to_message.forward_from then
					if message.reply_to_message.forward_from.id ~= self.info.id then
						local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.forward_from.id)
						if not res then
							mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
							return
						else
							mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
							return
						end
					end
				end
			end
		end
	end
end

return ban