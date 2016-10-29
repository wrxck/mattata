local yomama = {}
local mattata = require('mattata')
local JSON = require('dkjson')
local HTTP = require('socket.http')

function yomama:init(configuration)
	yomama.arguments = 'yomama'
	yomama.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yomama').table
	yomama.help = configuration.commandPrefix .. 'yomama - Tells a Yo\' Mama joke!'
end

function yomama:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.yomama)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat, output
	if string.match(jstr, 'Unable to connect to the db server.') then
		output = configuration.errors.connection
	else
		jdat = JSON.decode(jstr)
		output = jdat.joke
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return yomama