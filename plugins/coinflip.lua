local coinflip = {}
local functions = require('functions')
function coinflip:init(configuration)
	coinflip.command = 'coinflip (guess)'
	coinflip.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('coinflip', true):t('cf', true).table
	coinflip.doc = configuration.command_prefix .. 'coinflip (guess) - Flips a coin and returns the result! If no arguments are given, the result of a random coin flip is returned; if, however, an argument is given, the result of the random coin flip tests against your guess and returns the result and whether your guess was correct. Alias: ' .. configuration.command_prefix .. 'cf'
end
function coinflip:action(msg)
	local input = functions.input(msg.text)
	if input then
		local guess = input:gsub('heads', '1'):gsub('Heads', '1'):gsub('h', '1'):gsub('H', '1'):gsub('tails', '2'):gsub('Tails', '2'):gsub('t', 2):gsub('T', '2')
		local flip = math.random(2)
		local result = ''
		local output = ''
		if flip == 1 then
			result = 'Heads.'
		else
			result = 'Tails.'
		end
		if tonumber(guess) == flip then
			output = '*The coin landed on:* ' .. result .. ' _You were correct!_'
			functions.send_reply(msg, output, true)
			return
		else
			output = '*The coin landed on:* ' .. result .. ' _You weren\'t correct, try again!_'
			functions.send_reply(msg, output, true)
			return
		end
	else
		local flip = math.random(2)
		local result = ''
		if flip == 1 then
			result = 'Heads.'
		else
			result = 'Tails.'
		end
		local output = '*The coin landed on:* ' .. result
		functions.send_reply(msg, output, true)
		return
	end
end
return coinflip