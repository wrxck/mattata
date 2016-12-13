local ban = {}
local mattata = require('mattata')

function ban:init(configuration)
	ban.arguments = 'ban'
	ban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ban').table
	ban.help = configuration.commandPrefix .. 'ban - Bans the replied-to user. Forwarded messages are treated as if the user it was forwarded from had sent the message.'
end

function ban:onMessage(message, configuration)
	if not message.reply_to_message then
		mattata.sendMessage(message.chat.id, ban.help, nil, true, false, message.message_id)
		return
	end
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				for _, admin in ipairs(admin_list.result) do
					if admin.user.id == message.reply_to_message.from.id then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
						return
					elseif message.reply_to_message.from.id ~= self.info.id then
						if message.reply_to_message.forward_from then
							if message.reply_to_message.forward_from.id ~= self.info.id and admin.user.id ~= message.reply_to_message.forward_from.id then
								local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.forward_from.id)
								if not res then
									mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
									return
								else
									mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.forward_from.first_name .. '.', nil, true, false, message.message_id)
									mattata.sendMessage(configuration.kickLog, '<pre>' .. mattata.htmlEscape('Banned ' .. message.reply_to_message.forward_from.first_name .. ' (' .. message.reply_to_message.forward_from.id .. ') from ' .. message.chat.title .. ' (' .. message.chat.id .. ')') .. '</pre>', 'HTML', true, false)
									return
								end
							end
						else
							local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.from.id)
							if not res then
								mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
								return
							else
								mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
								mattata.sendMessage(configuration.kickLog, '<pre>' .. mattata.htmlEscape('Banned ' .. message.reply_to_message.from.first_name .. ' (' .. message.reply_to_message.from.id .. ') from ' .. message.chat.title .. ' (' .. message.chat.id .. ')') .. '</pre>', 'HTML', true, false)
								return
							end
						end
					end
				end
			end
		end
	end
end

return ban