local tobase64 = {}
local mattata = require('mattata')

local bit = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function tobase64:init(configuration)
	tobase64.arguments = 'tobase64 <string>'
	tobase64.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tobase64').table
	tobase64.help = configuration.commandPrefix .. 'tobase64 <string> - Converts the given string to base 64.'
end

function tobase64:encode(str)
	return ((str:gsub('.', function(x) 
		local r, bit = '', x:byte()
		for integer = 8, 1, -1 do
			r = r .. (bit % 2^integer - bit % 2^(integer - 1) > 0 and '1' or '0')
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
	end) .. ({ '', '==', '=' })[#str % 3 + 1])
end

function tobase64:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, tobase64.help, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, '```\n' .. tobase64:encode(input) .. '\n```', 'Markdown', true, false, channel_post.message_id)
end

function tobase64:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tobase64.help, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '```\n' .. tobase64:encode(input) .. '\n```', 'Markdown', true, false, message.message_id)
end

return tobase64