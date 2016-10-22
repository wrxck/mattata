local yeoldinsult = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function yeoldinsult:init(configuration)
	yeoldinsult.arguments = 'yeoldinsult'
	yeoldinsult.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yeoldinsult', true).table
	yeoldinsult.help = configuration.commandPrefix .. 'yeoldinsult - Insults you, the old-school way.' 
end

function yeoldinsult:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.yeoldinsult)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(msg.chat.id, jdat.insult, nil, true, false, msg.message_id, nil)
end

return yeoldinsult