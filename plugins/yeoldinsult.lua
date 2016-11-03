local yeoldinsult = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function yeoldinsult:init(configuration)
	yeoldinsult.arguments = 'yeoldinsult'
	yeoldinsult.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yeoldinsult').table
	yeoldinsult.help = configuration.commandPrefix .. 'yeoldinsult - Insults you, the old-school way.' 
end

function yeoldinsult:onMessageReceive(message, configuration)
	local jstr, res = HTTP.request(configuration.apis.yeoldinsult)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.insult, nil, true, false, message.message_id, nil)
end

return yeoldinsult