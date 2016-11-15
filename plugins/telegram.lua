local telegram = {}
local mattata = require('mattata')

function telegram:onNewChatMember(message, configuration)
	if message.new_chat_member.id ~= self.info.id then
		local joinChatMessages = configuration.joinChatMessages
		local output = joinChatMessages[math.random(#joinChatMessages)]
		mattata.sendMessage(message.chat.id, output:gsub('NAME', message.new_chat_member.first_name), nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'Hello, World! Thanks for adding me, ' .. message.from.first_name .. '!', nil, true, false, message.message_id)
end

function telegram:onLeftChatMember(message, configuration)
	if message.left_chat_member.id ~= self.info.id then
		local leftChatMessages = configuration.leftChatMessages
		local output = leftChatMessages[math.random(#leftChatMessages)]
		mattata.sendMessage(message.chat.id, output:gsub('NAME', message.left_chat_member.first_name), nil, true, false, message.message_id)
		return
	end
end

return telegram
