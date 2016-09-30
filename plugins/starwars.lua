local starwars = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function starwars:init(configuration)
	starwars.command = 'starwars <query>'
	starwars.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('starwars', true):t('sw', true).table
	starwars.documentation = configuration.command_prefix .. 'starwars <query> - Returns the opening crawl from the specified Star Wars film. Alias: ' .. configuration.command_prefix .. 'sw.'
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
function starwars:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, starwars.documentation)
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
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local jstr, res = HTTP.request(configuration.apis.starwars .. film)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = jdat.opening_crawl
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
	functions.send_reply(msg, output)
end
return starwars