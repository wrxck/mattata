local ban = {}
local mattata = require('mattata')

function ban:init(configuration)
	ban.arguments = 'ban'
	ban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ban').table
	ban.help = configuration.commandPrefix .. 'ban - Bans the replied-to user from the chat.'
end

function ban:onMessageReceive(msg, configuration)
	if msg.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(msg.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == msg.from.id then
				if not msg.reply_to_message then
					mattata.sendMessage(msg.chat.id, ban.help, nil, true, false, msg.message_id, nil)
					return
				end
				for _, admin in ipairs(admin_list.result) do
					if admin.user.id == msg.reply_to_message.from.id then
						mattata.sendMessage(msg.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, msg.message_id, nil)
						return
					end
				end
				if msg.reply_to_message.from.id ~= self.info.id then
					local res = mattata.kickChatMember(msg.chat.id, msg.reply_to_message.from.id)
					if not res then
						mattata.sendMessage(msg.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, msg.message_id, nil)
						return
					else
						mattata.sendMessage(msg.chat.id, 'Banned ' .. msg.reply_to_message.from.first_name .. '.', nil, true, false, msg.message_id, nil)
						return
					end
				end
				if msg.reply_to_message.forward_from then
					if msg.reply_to_message.forward_from.id ~= self.info.id then
						local res = mattata.kickChatMember(msg.chat.id, msg.reply_to_message.forward_from.id)
						if not res then
							mattata.sendMessage(msg.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, msg.message_id, nil)
							return
						else
							mattata.sendMessage(msg.chat.id, 'Banned ' .. msg.reply_to_message.from.first_name .. '.', nil, true, false, msg.message_id, nil)
							return
						end
					end
				end
			end
		end
	end
end

return ban
