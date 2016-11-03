local starwars = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function starwars:init(configuration)
	starwars.arguments = 'starwars <query>'
	starwars.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('starwars'):c('sw').table
	starwars.help = configuration.commandPrefix .. 'starwars <query> - Returns the opening crawl from the specified Star Wars film. Alias: ' .. configuration.commandPrefix .. 'sw.'
end

local films_by_number = {
	['phantom menace'] = 4,
	['attack of the clones'] = 5,
	['revenge of the sith'] = 6,
	['new hope'] = 1,
	['empire strikes back'] = 2,
	['return of the jedi'] = 3,
	['force awakens'] = 7
}

local corrected_numbers = {
	4,
	5,
	6,
	1,
	2,
	3,
	7
}

function starwars:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, starwars.help, nil, true, false, message.message_id, nil)
		return
	end
	local film
	if tonumber(input) then
		input = tonumber(input)
		film = corrected_numbers[input] or input
	else
		for title, number in pairs(films_by_number) do
			print(string.match(input, title))
			if string.match(input, title) then
				print(number)
				film = number
				break
			end
		end
	end
	if not film then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	local jstr, res = HTTP.request(configuration.apis.starwars .. film)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = jdat.opening_crawl
	mattata.sendChatAction(message.chat.id, 'typing')
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
end

return starwars