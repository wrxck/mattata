local tohex = {}
local functions = require('functions')
function tohex:init(configuration)
	tohex.command = 'tohex <string>'
	tohex.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('tohex', true).table
	tohex.documentation = configuration.command_prefix .. 'tohex <string> - Converts the given string to hexadecimal.'
end
function tohex:num(num)
	local hexstr = '0123456789abcdef'
	local s = ''
	while num > 0 do
		local mod = math.fmod(num, 16)
		s = string.sub(hexstr, mod+1, mod+1) .. s
		num = math.floor(num / 16)
	end
	if s == '' then s = '0' end
	return s
end
function tohex:str(str)
	local hex = ''
	while #str > 0 do
		local hb = tohex:num(string.byte(str, 1, 1))
		if #hb < 2 then hb = '0' .. hb end
		hex = hex .. hb
		str = string.sub(str, 2)
	end
	return hex
end
function tohex:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, tohex.documentation)
		return
	end
	functions.send_reply(msg, '`' .. tohex:str(input) .. '`', true)
end
return tohex