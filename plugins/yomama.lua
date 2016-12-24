local yomama = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function yomama:init(configuration)
	yomama.arguments = 'yomama'
	yomama.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('yomama').table
	yomama.help = configuration.commandPrefix .. 'yomama - Tells a Yo\' Mama joke!'
end

function yomama:onMessage(message, configuration, language)
	local jstr, res = http.request('http://api.yomomma.info/')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	if jstr:match('^Unable to connect to the da?t?a?ba?s?e? server%.?$') then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.joke, nil, true, false, message.message_id)
end

return yomama