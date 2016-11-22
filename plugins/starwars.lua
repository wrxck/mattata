local starwars = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function starwars:init(configuration)
	starwars.arguments = 'starwars <query>'
	starwars.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('starwars'):c('sw').table
	starwars.help = configuration.commandPrefix .. 'starwars <query> - Returns the opening crawl from the specified Star Wars film. Alias: ' .. configuration.commandPrefix .. 'sw.'
end

local filmsByNumber = {
	['phantom menace'] = 4,
	['attack of the clones'] = 5,
	['revenge of the sith'] = 6,
	['new hope'] = 1,
	['empire strikes back'] = 2,
	['return of the jedi'] = 3,
	['force awakens'] = 7
}

local correctedNumbers = { 4, 5, 6, 1, 2, 3, 7 }

function starwars:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, starwars.help, nil, true, false, channel_post.message_id)
		return
	end
	local film
	if tonumber(input) then
		input = tonumber(input)
		film = correctedNumbers[input] or input
	else
		for title, number in pairs(filmsByNumber) do
			if string.match(input, title) then
				film = number
				break
			end
		end
	end
	if not film then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://swapi.co/api/films/' .. film)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, jdat.opening_crawl, nil, true, false, channel_post.message_id)
end

function starwars:onMessage(message, language)
	mattata.sendChatAction(message.chat.id, 'typing')
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, starwars.help, nil, true, false, message.message_id)
		return
	end
	local film
	if tonumber(input) then
		input = tonumber(input)
		film = correctedNumbers[input] or input
	else
		for title, number in pairs(filmsByNumber) do
			if string.match(input, title) then
				film = number
				break
			end
		end
	end
	if not film then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://swapi.co/api/films/' .. film)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.opening_crawl, nil, true, false, message.message_id)
end

return starwars