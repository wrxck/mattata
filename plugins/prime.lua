local prime = {}
local mattata = require('mattata')

function prime:init(configuration)
	prime.arguments = 'prime <number>'
	prime.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('prime').table
	prime.help = configuration.commandPrefix .. 'prime <number> - Tells you if a number is prime or not.'
end

function isPrime(number)
	local primes = {}
	for i = 1, number do
		primes[i] = 1 ~= i
	end
	for i = 2, math.floor(math.sqrt(number)) do
		if primes[i] then
			for v = i * i, number, i do
				return number .. ' is NOT a prime number...'
			end
		end
	end
	return number .. ' is a prime number!'
end

function prime:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input or tonumber(input) == nil then
		mattata.sendMessage(channel_post.chat.id, prime.help, nil, true, false, channel_post.message_id)
		return
	elseif tonumber(input) > 999999 or tonumber(input) < 1 then
		mattata.sendMessage(channel_post.chat.id, 'Please enter a number between 1 and 999999', nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, isPrime(tonumber(input)), nil, true, false, channel_post.message_id)
end

function prime:onMessage(message)
	local input = mattata.input(message.text)
	if not input or tonumber(input) == nil then
		mattata.sendMessage(message.chat.id, prime.help, nil, true, false, message.message_id)
		return
	elseif tonumber(input) > 999999 or tonumber(input) < 1 then
		mattata.sendMessage(message.chat.id, 'Please enter a number between 1 and 999999', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, isPrime(tonumber(input)), nil, true, false, message.message_id)
end

return prime