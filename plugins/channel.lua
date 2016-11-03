local channel = {}
local mattata = require('mattata')

function channel:init(configuration)
	channel.arguments = 'ch <channel> \\n <message>'
	channel.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('ch').table
	channel.help = configuration.commandPrefix .. 'ch <channel> <message> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own and/or administrate.'
end

function channel:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	local output
	if input then
		local chat_id = mattata.getWord(input, 1)
		local admin_list, t = mattata.getChatAdministrators(chat_id)
		if admin_list then
			local is_admin = false
			for _, admin in ipairs(admin_list.result) do
				if admin.user.id == message.from.id then
					is_admin = true
				end
			end
			if is_admin then
				local text = input:match('\n(.+)')
				if text then
					local success = mattata.sendMessage(chat_id, text, 'Markdown', true, false, nil, nil)
					if success then
						output = 'Your message has been sent!'
					else
						output = 'Sorry, I was unable to send your message.'
					end
				else
					output = 'Please enter a message to send. Markdown formatting is supported.'
				end
			else
				output = 'Sorry, you do not appear to be an administrator for that group/channel.'
			end
		else
			output = 'Sorry, I was unable to retrieve a list of administrators for that group/channel.\n' .. t.description
		end
	else
		output = channel.help
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
end

return channel