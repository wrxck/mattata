local channel = {}
local telegram_api = require('telegram_api')
local functions = require('functions')
function channel:init(configuration)
	channel.command = 'ch <channel> \\n <message>'
	channel.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ch', true).table
	channel.doc = configuration.command_prefix .. [[ch <channel> <message> Sends a message to a Telegram channel. The channel can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels they own and/or administrate. The message to send must be on a new line (after the command and its respective syntax)]]
end
function channel:action(msg, configuration)
	local input = functions.input(msg.text)
	local output
	if input then
		local chat_id = functions.get_word(input, 1)
		local admin_list, t = telegram_api.getChatAdministrators(self, { chat_id = chat_id } )
		if admin_list then
			local is_admin = false
			for _, admin in ipairs(admin_list.result) do
				if admin.user.id == msg.from.id then
					is_admin = true
				end
			end
			if is_admin then
				local text = input:match('\n(.+)')
				if text then
					local success, result = functions.send_message(self, chat_id, text, true, nil, true)
					if success then
						output = 'Your message has been sent!'
					else
						output = 'Sorry, I was unable to send your message.\n`' .. result.description .. '`'
					end
				else
					output = 'Please enter a message to send. Markdown formatting is supported!'
				end
			else
				output = 'Sorry, you do not appear to be an administrator for that channel.'
			end
		else
			output = 'Sorry, I was unable to retrieve a list of administrators for that channel.\n`' .. t.description .. '`'
		end
	else
		output = channel.doc
	end
	functions.send_reply(self, msg, output, true)
end
return channel