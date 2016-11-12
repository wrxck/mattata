local doge = {}
local mattata = require('mattata')
local URL = require('socket.url')

function doge:init(configuration)
	doge.arguments = 'doge <text>'
	doge.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('doge').table
	doge.help = configuration.commandPrefix .. 'doge <text> - Doge-ifies the given text. Sentences are separated using slashes. Example: ' .. configuration.commandPrefix .. 'doge hello world/this is a test sentence'
end

function doge:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, doge.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = 'http://dogr.io/' .. input:gsub(' ', '%%20') .. '.png?split=false&.png'
	local matches = 'https?://[%%%w-_%.%?%.:/%+=&]+' -- Credit to @yagop for this snippet.
	if string.match(url, matches) == url then
		mattata.sendPhoto(message.chat.id, url)
		return
	else
		mattata.sendMessage(message.chat.id, 'I could not generate an image with those parameters.', nil, true, false, message.message_id)
		return
	end
end

return doge