local loremipsum = {}
local mattata = require('mattata')
local HTTP = require('socket.http')

function loremipsum:init(configuration)
	loremipsum.arguments = 'loremipsum'
	loremipsum.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('loremipsum').table
	loremipsum.help = configuration.commandPrefix .. 'loremipsum - Generates a few Lorem Ipsum sentences!'
end

function loremipsum:onChannelPost(channel_post, configuration)
	local str, res = HTTP.request('http://loripsum.net/api/1/medium/plaintext')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, str, nil, true, false, channel_post.message_id)
end

function loremipsum:onMessage(message, language)
	local str, res = HTTP.request('http://loripsum.net/api/1/medium/plaintext')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, str, nil, true, false, message.message_id)
end

return loremipsum