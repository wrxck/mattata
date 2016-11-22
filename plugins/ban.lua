local ban = {}
local mattata = require('mattata')

function ban:init(configuration)
	ban.arguments = 'ban <user>'
	ban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ban').table
	ban.help = configuration.commandPrefix .. 'ban <user> - Bans the targeted user from the chat. If the command is executed via reply, then the replied-to user is banned.'
end

function getUserId(user)
	if not mattata.getChat(user) then
		return false
	end
	local request = mattata.getChat(user)
	return request.result.id
end

function ban:onMessage(message)
	local input = mattata.input(message.text)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message then
					if not input then
						mattata.sendMessage(message.chat.id, ban.help, nil, true, false, message.message_id)
						return
					end
					if tonumber(input) == nil and (not input:match('^@')) then
						input = '@' .. input
					end
					if not mattata.getChat(input) then
						mattata.sendMessage(message.chat.id, 'Invalid username or ID.', nil, true, false, message.message_id)
						return
					end
					local res = mattata.kickChatMember(message.chat.id, tonumber(getUserId(input)))
					if not res then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the targeted user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
						return
					end
					mattata.sendMessage(message.chat.id, 'Banned ' .. input .. '.', nil, true, false, message.message_id)
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
					end
					mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
					return
				end
				if message.reply_to_message.forward_from and message.reply_to_message.forward_from.id ~= self.info.id then
					local res = mattata.kickChatMember(message.chat.id, message.reply_to_message.forward_from.id)
					if not res then
						mattata.sendMessage(message.chat.id, 'An error occured. Please ensure you have granted me administrative permissions and that the replied-to user is in this group, and isn\'t an administrator.', nil, true, false, message.message_id)
						return
					end
					mattata.sendMessage(message.chat.id, 'Banned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id)
					return
				end
			end
		end
	end
end

return ban