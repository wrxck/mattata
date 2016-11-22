local doge = {}
local mattata = require('mattata')
local URL = require('socket.url')

function doge:init(configuration)
	doge.arguments = 'doge <text>'
	doge.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('doge').table
	doge.help = configuration.commandPrefix .. 'doge <text> - Doge-ifies the given text. Sentences are separated using slashes. Example: ```\n' .. configuration.commandPrefix .. 'doge hello world\nthis is a test sentence\nmake sure you type like this\nelse it won\'t work!\n```'
end

function doge:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, doge.help, nil, true, false, channel_post.message_id)
		return
	end
	local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
	local pattern = 'https?://[%%%w-_%.%?%.:/%+=&]+'
	if string.match(url, pattern) == url then
		mattata.sendPhoto(channel_post.chat.id, url)
		return
	end
	mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
end

function doge:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, doge.help, nil, true, false, message.message_id)
		return
	end
	local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
	local pattern = 'https?://[%%%w-_%.%?%.:/%+=&]+'
	if string.match(url, pattern) == url then
		mattata.sendPhoto(message.chat.id, url)
		return
	end
	mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
end

return doge