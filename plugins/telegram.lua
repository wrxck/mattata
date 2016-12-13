local telegram = {}
local mattata = require('mattata')

function telegram:onNewChatMember(message, configuration, language)
	if message.new_chat_member.id ~= self.info.id then
		local joinChatMessages = language.joinChatMessages
		local output = joinChatMessages[math.random(#joinChatMessages)]
		mattata.sendMessage(message.chat.id, output:gsub('NAME', message.new_chat_member.first_name), nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, language.userAddedBot:gsub('NAME', message.from.first_name), nil, true, false, message.message_id)
end

function telegram:onLeftChatMember(message, configuration, language)
	if message.left_chat_member.id ~= self.info.id and message.left_chat_member.id == message.from.id then
		local leftChatMessages = language.leftChatMessages
		local output = leftChatMessages[math.random(#leftChatMessages)]
		mattata.sendMessage(message.chat.id, output:gsub('NAME', message.left_chat_member.first_name), nil, true, false, message.message_id)
		return
	end
end

return telegram