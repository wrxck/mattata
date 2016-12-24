local base64 = {}
local mattata = require('mattata')

function base64:init(configuration)
	base64.arguments = 'base64 <string>'
	base64.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('base64').table
	base64.help = configuration.commandPrefix .. 'base64 <string> - Converts the given string to base64.'
end

function base64.encode(str)
	local bit = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((str:gsub('.', function(x) 
		local r, bit = '', x:byte()
		for integer = 8, 1, -1 do r = r .. (bit % 2^integer - bit % 2^(integer - 1) > 0 and '1' or '0') end
		return r;
	end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return end
		local c = 0
		for integer = 1, 6 do c = c + (x:sub(integer, integer) == '1' and 2^(6 - integer) or 0) end
		return bit:sub(c + 1, c + 1)
	end) .. ({ '', '==', '=' })[#str % 3 + 1])
end

function base64:onMessage(message)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, base64.help, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, '<pre>' .. mattata.htmlEscape(base64.encode(input)) .. '</pre>', 'HTML', true, false, message.message_id)
end

return base64