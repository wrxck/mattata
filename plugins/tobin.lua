-- Credit to @hstntn for the original plugin

local tobin = {}
local mattata = require('mattata')

function tobin:init(configuration)
	tobin.arguments = 'tobin <number>'
	tobin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tobin').table
	tobin.help = configuration.commandPrefix .. 'tobin <number> - Converts the given number to binary.'
end

function tobin:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tobin.help, nil, true, false, message.message_id, nil)
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
	mattata.sendMessage(message.chat.id, '`' .. string.rep('0', numberZero) .. numberString .. '`', 'Markdown', true, false, message.message_id)
end

return tobin