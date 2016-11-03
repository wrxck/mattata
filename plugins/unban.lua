local unban = {}
local mattata = require('mattata')

function unban:init(configuration)
	unban.arguments = 'unban'
	unban.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('unban').table
	unban.help = configuration.commandPrefix .. 'unban - Unbans the replied-to user from the chat.'
end

function unban:onMessageReceive(message, configuration)
	if message.chat.type ~= 'private' then
		local admin_list = mattata.getChatAdministrators(message.chat.id)
		for _, admin in ipairs(admin_list.result) do
			if admin.user.id == message.from.id then
				if not message.reply_to_message then
					mattata.sendMessage(message.chat.id, unban.help, nil, true, false, message.message_id, nil)
					return
				end
				if message.reply_to_message.from.id ~= self.info.id then
					local res = mattata.unbanChatMember(message.chat.id, message.reply_to_message.from.id)
					if res then
						mattata.sendMessage(message.chat.id, 'Unbanned ' .. message.reply_to_message.from.first_name .. '.', nil, true, false, message.message_id, nil)
						return
					end
				end
			end
		end
	end
end

return unban