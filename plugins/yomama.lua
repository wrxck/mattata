local yomama = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function yomama:init(configuration)
	yomama.arguments = 'yomama'
	yomama.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yomama').table
	yomama.help = configuration.commandPrefix .. 'yomama - Tells a Yo\' Mama joke!'
end

function yomama:onChannelPostReceive(channel_post, configuration)
	local jstr, res = HTTP.request('http://api.yomomma.info/')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	if jstr:match('Unable to connect to the db server%.') then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, jdat.joke, nil, true, false, channel_post.message_id)
end

function yomama:onMessageReceive(message, language)
	local jstr, res = HTTP.request('http://api.yomomma.info/')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	if jstr:match('Unable to connect to the db server%.') then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.joke, nil, true, false, message.message_id)
end

return yomama