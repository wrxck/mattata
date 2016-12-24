local tobin = {}
local mattata = require('mattata')

function tobin:init(configuration)
	tobin.arguments = 'tobin <number>'
	tobin.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('tobin').table
	tobin.help = configuration.commandPrefix .. 'tobin <number> - Converts the given number to binary.'
end

function tobin:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, tobin.help, nil, true, false, message.message_id)
		return
	elseif tonumber(input) == nil then
		mattata.sendMessage(message.chat.id, 'Input must be numeric.', nil, true, false, message.message_id)
		return
	end
	local result = ''
	local split, integer, fraction
	repeat
		split = tonumber(input) / 2
		integer, fraction = math.modf(split)
		input = integer
		result = math.ceil(fraction) .. result
	until input == 0
	local str = result:format('s')
	local zero = 16 - str:len()
	mattata.sendMessage(message.chat.id, '<pre>' .. string.rep('0', zero) .. str .. '</pre>', 'HTML', true, false, message.message_id)
end

return tobin