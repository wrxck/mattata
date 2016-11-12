local copypasta = {}
local mattata = require('mattata')

function copypasta:init(configuration)
	copypasta.arguments = 'copypasta'
	copypasta.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('copypasta'):c('😂').table
	copypasta.help = configuration.commandPrefix .. 'copypasta - Riddles the replied-to message with cancerous emoji. Alias: ' .. configuration.commandPrefix .. '😂.'
end

function copypasta:onMessageReceive(message, configuration)
	if not message.reply_to_message then
		mattata.sendMessage(message.chat.id, copypasta.help, nil, true, false, message.message_id)
		return
	end
	local output = io.popen('python3 plugins/copypasta.py ' .. message.reply_to_message.text_upper:gsub('\n', ' '):gsub('\'', '')):read('*all')
	local res = mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
	if not res then
		mattata.sendMessage(message.chat.id, 'The replied-to message must contain alpha-numeric characters!', nil, true, false, message.message_id)
		return
	end
end

return copypasta