local frombin = {}
local mattata = require('mattata')

function frombin:init(configuration)
	frombin.arguments = 'frombin <binary>'
	frombin.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('frombin').table
	frombin.help = configuration.commandPrefix .. 'frombin <binary> - Converts the given string of binary to a numerical value.'
end

function frombin:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, frombin.help, nil, true, false, message.message_id) return end
	if input:gsub('0', ''):gsub('1', '') ~= '' then mattata.sendMessage(message.chat.id, 'The inputted string must be in binary format.', nil, true, false, message.message_id) return end
	local number = 0
	local ex = input:len() - 1
	local l = 0
	l = ex + 1
	for i = 1, l do
		b = input:sub(i, i)
		if b == '1' then number = number + 2^ex end
		ex = ex - 1
	end
	mattata.sendMessage(message.chat.id, '<pre>' .. number .. '</pre>', 'HTML', true, false, message.message_id)
end

return frombin