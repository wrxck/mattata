local tohex = {}
local mattata = require('mattata')

function tohex:init(configuration)
	tohex.arguments = 'tohex <string>'
	tohex.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tohex').table
	tohex.help = configuration.commandPrefix .. 'tohex <string> - Converts the given string to hexadecimal.'
end

function numberToHex(int)
	local hexString = '0123456789abcdef'
	local s = ''
	while int > 0 do
		local mod = math.fmod(int, 16)
		s = string.sub(hexString, mod + 1, mod +1 ) .. s
		int = math.floor(int / 16)
	end
	if s == '' then
		s = '0'
	end
	return s
end

function stringToHex(str)
	local hex = ''
	while #str > 0 do
		local hb = numberToHex(string.byte(str, 1, 1))
		if #hb < 2 then hb = '0' .. hb end
		hex = hex .. hb
		str = string.sub(str, 2)
	end
	return hex
end

function tohex:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, tohex.help, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, '```\n' .. stringToHex(input) .. '\n```', 'Markdown', true, false, channel_post.message_id)
end

function tohex:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tohex.help, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '```\n' .. stringToHex(input) .. '\n```', 'Markdown', true, false, message.message_id)
end

return tohex