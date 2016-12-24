local synonym = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function synonym:init(configuration)
	synonym.arguments = 'synonym <word>'
	synonym.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('synonym').table
	synonym.help = configuration.commandPrefix .. 'synonym <word> - Sends a synonym of the given word.'
end

function synonym:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, synonym.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = https.request('https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=' .. configuration.keys.synonym .. '&lang=' .. configuration.language .. '-' .. configuration.language .. '&text=' .. url.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	if jstr == '{"head":{},"def":[]}' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'You could use the word <b>' .. jdat.def[1].tr[1].text .. '</b> instead.', 'HTML', true, false, message.message_id)
end

return synonym