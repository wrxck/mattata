local tohex = {}
local mattata = require('mattata')

function tohex:init(configuration)
	tohex.arguments = 'tohex <string>'
	tohex.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('tohex').table
	tohex.help = configuration.commandPrefix .. 'tohex <string> - Converts the given string to hexadecimal.'
end

function tohex.numberToHex(int)
	local hex = '0123456789abcdef'
	local s = ''
	while int > 0 do
		local mod = math.fmod(int, 16)
		s = hex:sub(mod + 1, mod +1 ) .. s
		int = math.floor(int / 16)
	end
	if s == '' then s = '0' end
	return s
end

function tohex.stringToHex(str)
	local hex = ''
	while #str > 0 do
		local hb = tohex.numberToHex(string.byte(str, 1, 1))
		if #hb < 2 then hb = '0' .. hb end
		hex = hex .. hb
		str = str:sub(2)
	end
	return hex
end

function tohex:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tohex.help, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '<pre>' .. mattata.htmlEscape(tohex.stringToHex(input)) .. '</pre>', 'HTML', true, false, message.message_id)
end

return tohex