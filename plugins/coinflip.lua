local coinflip = {}
local mattata = require('mattata')

function coinflip:init(configuration)
	coinflip.arguments = 'coinflip <guess>'
	coinflip.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('coinflip'):c('cf').table
	coinflip.help = configuration.commandPrefix .. 'coinflip <guess> - Flips a coin and returns the result! If no arguments are given, the result of a random coin flip is returned; if, however, an argument is given, the result of the random coin flip tests against your guess and returns the result and whether your guess was correct. Alias: ' .. configuration.commandPrefix .. 'cf.'
end

function coinflip:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text_lower):gsub('heads', '1'):gsub('h', '1'):gsub('tails', '2'):gsub('t', '2')
	local result = 'Heads.'
	local flip = math.random(2)
	if not input then
		if flip ~= 1 then
			result = 'Tails.'
		end
		mattata.sendMessage(channel_post.chat.id, '*The coin landed on:* ' .. result, 'Markdown', true, false, channel_post.message_id)
		return
	elseif input and tonumber(input) > 0 and tonumber(input) < 3 then
		input = tonumber(input)
		if flip ~= 1 then
			result = 'Tails.'
		end
		if input == flip then
			mattata.sendMessage(channel_post.chat.id, '*The coin landed on:* ' .. result .. ' _You were correct!_', 'Markdown', true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*The coin landed on:* ' .. result .. ' _You weren\'t correct, try again!_', 'Markdown', true, false, channel_post.message_id)
	end
end

function coinflip:onMessage(message)
	local input = mattata.input(message.text_lower):gsub('heads', '1'):gsub('h', '1'):gsub('tails', '2'):gsub('t', '2')
	local result = 'Heads.'
	local flip = math.random(2)
	if not input then
		if flip ~= 1 then
			result = 'Tails.'
		end
		mattata.sendMessage(message.chat.id, '*The coin landed on:* ' .. result, 'Markdown', true, false, message.message_id)
		return
	elseif input and tonumber(input) > 0 and tonumber(input) < 3 then
		input = tonumber(input)
		if flip ~= 1 then
			result = 'Tails.'
		end
		if input == flip then
			mattata.sendMessage(message.chat.id, '*The coin landed on:* ' .. result .. ' _You were correct!_', 'Markdown', true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*The coin landed on:* ' .. result .. ' _You weren\'t correct, try again!_', 'Markdown', true, false, message.message_id)
	end
end

return coinflip