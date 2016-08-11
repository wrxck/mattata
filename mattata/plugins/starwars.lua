local starwars = {}

local HTTP = require('socket.http')
local JSON = require('dkjson')
local bindings = require('mattata.bindings')
local utilities = require('mattata.utilities')

starwars.command = 'starwars <query>'

function starwars:init(config)
	starwars.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('starwars', true):t('sw', true).table
	starwars.doc = config.cmd_pat .. [[starwars <query>
Returns the opening crawl from the specified Star Wars film.
Alias: ]] .. config.cmd_pat .. 'sw'
end

function starwars:action(msg, config)

	bindings.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' } )

	local input = utilities.input(msg.text_lower)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			utilities.send_message(self, msg.chat.id, starwars.doc, true, msg.message_id, true)
			return
		end
	end

	local url = 'http://swapi.co'

	local sw_url = url .. '/api/films/' .. input:gsub('the phantom menace', '1'):gsub('attack of the clones', '2'):gsub('return of the jedi', '3'):gsub('a new hope', '4'):gsub('the empire strikes back', '5'):gsub('revenge of the sith', '6'):gsub('the force awakens', '7')
	local sw_jstr, res = HTTP.request(sw_url)
	if res ~= 200 then
		utilities.send_reply(self, msg, config.errors.connection)
		return
	end

	local sw_jdat = JSON.decode(sw_jstr)

	local output = '*' .. sw_jdat.opening_crawl .. '*'

	utilities.send_message(self, msg.chat.id, output, true, nil, true)

end

return starwars
