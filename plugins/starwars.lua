local starwars = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local telegram_api = require('telegram_api')
local functions = require('functions')
function starwars:init(configuration)
	starwars.command = 'starwars <query>'
	starwars.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('starwars', true):t('sw', true).table
	starwars.doc = configuration.command_prefix .. 'starwars <query> - Returns the opening crawl from the specified Star Wars film. Alias:' .. configuration.command_prefix .. 'sw'
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
	local input = functions.input(msg.text_lower)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_reply(self, msg, starwars.doc, true)
			return
		end
	end
	telegram_api.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' } )
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
		functions.send_reply(self, msg, configuration.errors.results)
		return
	end
	local url = configuration.starwars_api .. film
	local jstr, code = HTTP.request(url)
	if code ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection)
		return
	end
	local output = '*' .. JSON.decode(jstr).opening_crawl .. '*'
	functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return starwars