local istuesday = {}
local mattata = require('mattata')
local HTTP = require('socket.http')

function istuesday:init(configuration)
	istuesday.arguments = 'istuesday'
	istuesday.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('istuesday'):c('iit').table
	istuesday.help = configuration.commandPrefix .. 'istuesday - Tells you if it\'s Tuesday or not. Alias: ' .. configuration.commandPrefix .. 'iit.'
end

function istuesday:onChannelPost(channel_post, configuration)
	local str, res = HTTP.request('http://www.studentology.net/tuesday')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	if str:match('YES') then
		mattata.sendMessage(channel_post.chat.id, 'Yes, it\'s Tuesday!', nil, true, false, channel_post.message_id)
	else
		mattata.sendMessage(channel_post.chat.id, 'No, it\'s not Tuesday...', nil, true, false, channel_post.message_id)
	end
end

function istuesday:onMessage(message, language)
	local str, res = HTTP.request('http://www.studentology.net/tuesday')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	if str:match('YES') then
		mattata.sendMessage(message.chat.id, 'Yes, it\'s Tuesday!', nil, true, false, message.message_id)
	else
		mattata.sendMessage(message.chat.id, 'No, it\'s not Tuesday...', nil, true, false, message.message_id)
	end
end

return istuesday