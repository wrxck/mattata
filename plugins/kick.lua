local kick = {}
local mattata = require('mattata')

function kick:init(configuration)
	kick.arguments = 'kick <user>'
	kick.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('kick').table
	kick.help = configuration.commandPrefix .. 'kick <user> - Kicks the targeted user from the chat. If the command is executed via reply, then the replied-to user is kicked.'
end

function validateUser(user)
	local res = mattata.getChat(user)
	if not res then
		return false
	end
	return true
end

function getUserId(user)
	if not validateUser(user) then
		return false
	end
	local request = mattata.getChat(user)
	return request.result.id
end

function kick:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message then
					if not input then
						mattata.sendMessage(message.chat.id, kick.help, nil, true, false, message.message_id)
						return
					else
						if tonumber(input) == nil then
							if not string.match(input, '^@') then
								input = '@' .. input
							end
						end
						if not validateUser(input) then
							mattata.sendMessage(message.chat.id, 'Invalid username or ID.', nil, true, false, message.message_id)
							return
						else
							local res = mattata.kickChatMember(message.chat.id, tonumber(getUserId(input)))
							if not res then
								mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the targeted user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
								return
							else
								mattata.sendMessage(message.chat.id, 'Kicked ' .. input .. '.', nil, true, false, message.message_id)
								mattata.unbanChatMember(message.chat.id, tonumber(getUserId(input)))
							end
						end
					end
				else
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
							mattata.sendMessage(message.chat.id, 'Kicked ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
							mattata.unbanChatMember(message.chat.id, message.reply_to_message.from.id)
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
								mattata.sendMessage(message.chat.id, 'Kicked ' .. message.reply_to_message.forward_from.first_name .. '.', nil, true, false, message.message_id)
								mattata.unbanChatMember(message.chat.id, message.reply_to_message.forward_from.id)
								return
							end
						end
					end
				end
			end
		end
	end
end

return kick