local insult = {}
local mattata = require('mattata')
local http = require('socket.http')

function insult:init(configuration)
	insult.arguments = 'insult'
	insult.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('insult').table
	insult.help = configuration.commandPrefix .. 'insult - Sends a random insult.'
end

function insult:onMessage(message, configuration, language)
	local insult, res = http.request('http://datahamster.com/autoinsult/index.php?style=' .. math.random(0, 3))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	mattata.sendMessage(message.chat.id, insult:match('%<div class%=%"insult%" id%=%"insult%"%>(.-)%<%/div%>'), nil, true, false, message.message_id)
end

return insult