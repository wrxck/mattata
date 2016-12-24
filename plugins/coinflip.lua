local coinflip = {}
local mattata = require('mattata')

function coinflip:init(configuration)
	coinflip.arguments = 'coinflip <guess>'
	coinflip.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('coinflip'):command('cf').table
	coinflip.help = configuration.commandPrefix .. 'coinflip <guess> - Flips a coin and returns the result! If no arguments are given, the result of a random coin flip is returned; if, however, an argument is given, the result of the random coin flip tests against your guess and returns the result and whether your guess was correct. Alias: ' .. configuration.commandPrefix .. 'cf.'
end

function coinflip:onMessage(message)
	local input = mattata.input(message.text_lower):gsub('heads', '1'):gsub('tails', '2')
	local result = 'Heads.'
	local flip = math.random(2)
	if not input then
		if flip ~= 1 then result = 'Tails.' end
		mattata.sendMessage(message.chat.id, '<b>The coin landed on:</b> ' .. result, 'HTML', true, false, message.message_id)
	elseif tonumber(input) == 1 or tonumber(input) == 2 then
		input = tonumber(input)
		if flip ~= 1 then result = 'Tails.' end
		if input == flip then mattata.sendMessage(message.chat.id, '<b>The coin landed on:</b> ' .. result .. '\n<i>You were correct!</i>', 'HTML', true, false, message.message_id) return end
		mattata.sendMessage(message.chat.id, '<b>The coin landed on:</b> ' .. result .. '\n<i>You weren\'t correct, try again...</i>', 'HTML', true, false, message.message_id)
	else mattata.sendMessage(message.chat.id, 'Invalid arguments. You must specify your guess, either \'heads\' or \'tails\'.', nil, true, false, message.message_id) end
end

return coinflip