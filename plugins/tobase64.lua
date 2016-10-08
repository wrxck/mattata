local tobase64 = {}
local functions = require('functions')
function tobase64:init(configuration)
	tobase64.command = 'tobase64 <string>'
	tobase64.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('tobase64', true).table
	tobase64.documentation = configuration.command_prefix .. '/tobase64 <string> - Converts the given string to bit64.'
end
local bit = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function tobase64:encode(str)
	return ((str:gsub('.', function(x) 
		local r, bit = '', x:byte()
		for integer = 8, 1, -1 do
			r = r .. (bit%2^integer - bit%2^(integer - 1) > 0 and '1' or '0')
		end
		return r;
	end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then
			return
		end
		local c = 0
		for integer = 1, 6 do
			c = c + (x:sub(integer, integer) == '1' and 2^(6 - integer) or 0)
		end
		return bit:sub(c + 1, c + 1)
	end) .. ({ '', '==', '=' })[#str%3 + 1])
end
function tobase64:action(msg)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, tobase64.documentation)
		return
	end
	functions.send_reply(msg, '`' .. tobase64:encode(input) .. '`', true)
end
return tobase64