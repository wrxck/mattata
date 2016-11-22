-- Credit to @hstntn for the original plugin

local tobin = {}
local mattata = require('mattata')

function tobin:init(configuration)
	tobin.arguments = 'tobin <number>'
	tobin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tobin').table
	tobin.help = configuration.commandPrefix .. 'tobin <number> - Converts the given number to binary.'
end

function tobin:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, tobin.help, nil, true, false, channel_post.message_id)
		return
	end
	input = tonumber(input)
	if input == nil then
		mattata.sendMessage(channel_post.chat.id, 'Input must be numeric.', nil, true, false, channel_post.message_id)
		return
	end
	input = channel_post.text_lower:gsub('^' .. configuration.commandPrefix .. 'tobin ', '')
	local result = ''
	local split, integer, fraction
	repeat
		split = input / 2
		integer, fraction = math.modf(split)
		input = integer
		result = math.ceil(fraction) .. result
	until input == 0
	local numberString = string.format(result, 's')
	local numberZero = 16 - string.len(numberString)
	mattata.sendMessage(channel_post.chat.id, '```\n' .. string.rep('0', numberZero) .. numberString .. '\n```', 'Markdown', true, false, channel_post.message_id)
end

function tobin:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tobin.help, nil, true, false, message.message_id)
		return
	end
	input = tonumber(input)
	if input == nil then
		mattata.sendMessage(message.chat.id, 'Input must be numeric.', nil, true, false, message.message_id)
		return
	end
	input = message.text_lower:gsub('^' .. configuration.commandPrefix .. 'tobin ', '')
	local result = ''
	local split, integer, fraction
	repeat
		split = input / 2
		integer, fraction = math.modf(split)
		input = integer
		result = math.ceil(fraction) .. result
	until input == 0
	local numberString = string.format(result, 's')
	local numberZero = 16 - string.len(numberString)
	mattata.sendMessage(message.chat.id, '```\n' .. string.rep('0', numberZero) .. numberString .. '\n```', 'Markdown', true, false, message.message_id)
end

return tobin