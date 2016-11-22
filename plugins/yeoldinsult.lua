local yeoldinsult = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function yeoldinsult:init(configuration)
	yeoldinsult.arguments = 'yeoldinsult'
	yeoldinsult.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yeoldinsult').table
	yeoldinsult.help = configuration.commandPrefix .. 'yeoldinsult - Insults you, the old-school way.' 
end

function yeoldinsult:onChannelPost(channel_post, configuration)
	local jstr, res = HTTP.request('http://quandyfactory.com/insult/json')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, jdat.insult, nil, true, false, channel_post.message_id)
end

function yeoldinsult:onMessage(message, language)
	local jstr, res = HTTP.request('http://quandyfactory.com/insult/json')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.insult, nil, true, false, message.message_id)
end

return yeoldinsult