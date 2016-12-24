local unicode = {}
local mattata = require('mattata')
local json = require('dkjson')

function unicode:init(configuration)
	unicode.arguments = 'unicode <text>'
	unicode.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('unicode').table
	unicode.help = configuration.commandPrefix .. 'unicode <text> - Returns the given text as a json-encoded table of Unicode (UTF-32) values.'
end

function unicode:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, unicode.help, nil, true, false, message.message_id)
		return
	else input = tostring(input) end
	local res = {}
	local seq = 0
	local val = nil
	for i = 1, #input do
		local char = string.byte(input, i)
		if seq == 0 then
			table.insert(res, val)
			seq = char < 0x80 and 1 or char < 0xE0 and 2 or char < 0xF0 and 3 or char < 0xF8 and 4 or error('invalid UTF-8 character sequence')
			val = bit32.band(char, 2 ^ (8 - seq) - 1)
		else val = bit32.bor(bit32.lshift(val, 6), bit32.band(char, 0x3F)) end
		seq = seq - 1
	end
	table.insert(res, val)
	mattata.sendMessage(message.chat.id, '<pre>' .. json.encode(res) .. '</pre>', 'HTML', true, false, message.message_id)
end

return unicode