local channel = {}
local mattata = require('mattata')

function channel:init(configuration)
	channel.arguments = 'ch <channel> \\n <message>'
	channel.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('ch').table
	channel.help = configuration.commandPrefix .. 'ch <channel> <message> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own and/or administrate. \\n means a line break.'
end

function channel:onMessage(message, configuration, language)
	if message.chat.type == 'channel' then return end
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, channel.help, nil, true, false, message.message_id) return end
	local targetChat = mattata.getWord(input, 1)
	local adminList, res = mattata.getChatAdministrators(targetChat)
	if not adminList and not mattata.isConfiguredAdmin(message.from.id) then
		mattata.sendMessage(message.chat.id, language.unableToRetrieveChannelAdmins, nil, true, false, message.message_id)
		return
	elseif not mattata.isConfiguredAdmin(message.from.id) then -- Make OP users an exception
		local isAdmin = false
		for _, admin in ipairs(adminList.result) do if admin.user.id == message.from.id then isAdmin = true end end
		if not isAdmin then mattata.sendMessage(message.chat.id, language.notChannelAdmin, nil, true, false, message.message_id) return end
	end
	local text = input:match('\n(.+)')
	if not text then mattata.sendMessage(message.chat.id, language.enterMessageToSendToChannel, nil, true, false, message.message_id) return end
	local post = mattata.sendMessage(targetChat, text, 'Markdown', true, false)
	if not post then mattata.sendMessage(message.chat.id, language.unableToSendToChannel, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, language.messageSentToChannel, nil, true, false, message.message_id)
end

return channel