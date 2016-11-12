local frombin = {}
local mattata = require('mattata')

function frombin:init(configuration)
	frombin.arguments = 'frombin <binary>'
	frombin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('frombin').table
	frombin.help = configuration.commandPrefix .. 'frombin <binary> - Converts the given string of binary to a number.'
end

function frombin:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, frombin.help, nil, true, false, message.message_id, nil)
		return
	end
	input = tonumber(input)
	if input == nil then
		mattata.sendMessage(message.chat.id, 'Input must be a string of binary.', nil, true, false, message.message_id)
		return
	end
	input = message.text_lower:gsub('^' .. configuration.commandPrefix .. 'frombin ', '')
	local number = 0
	local ex = string.len(input) - 1
	local l = 0
	l = ex + 1
	for i = 1, l do
		b = string.sub(input, i, i)
		if b == '1' then
			number = number + 2^ex
		end
		ex = ex - 1
	end
	mattata.sendMessage(message.chat.id, '`' .. number .. '`', 'Markdown', true, false, message.message_id)
end

return frombin