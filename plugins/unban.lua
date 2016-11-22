local unban = {}
local mattata = require('mattata')

function unban:init(configuration)
	unban.arguments = 'unban <user>'
	unban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('unban').table
	unban.help = configuration.commandPrefix .. 'unban <user> - Unbans the targeted user from the chat. If the command is executed via reply, then the replied-to user is unbanned.'
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

function unban:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message then
					if not input then
						mattata.sendMessage(message.chat.id, ban.help, nil, true, false, message.message_id)
						return
					else
						if tonumber(input) == nil then
							if not string.match(input, '^@') then
								input = '@' .. input
							end
						end
						if not validateUser(input) then
							mattata.sendMessage(message.chat.id, 'Invalid username or ID - or the API is down, try using it via reply.', nil, true, false, message.message_id)
							return
						else
							local res = mattata.unbanChatMember(message.chat.id, tonumber(getUserId(input)))
							if not res then
								mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the targeted user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
								return
							else
								mattata.sendMessage(message.chat.id, 'Unbanned ' .. input .. '.', nil, true, false, message.message_id)
								return
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
						local res = mattata.unbanChatMember(message.chat.id, message.reply_to_message.from.id)
						if not res then
							mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
							return
						else
							mattata.sendMessage(message.chat.id, 'Unbanned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
							return
						end
					end
					if message.reply_to_message.forward_from then
						if message.reply_to_message.forward_from.id ~= self.info.id then
							local res = mattata.unbanChatMember(message.chat.id, message.reply_to_message.forward_from.id)
							if not res then
								mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
								return
							else
								mattata.sendMessage(message.chat.id, 'Unbanned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
								return
							end
						end
					end
				end
			end
		end
	end
end

return unban