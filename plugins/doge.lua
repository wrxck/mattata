local doge = {}
local mattata = require('mattata')

function doge:init(configuration)
	doge.arguments = 'doge <text>'
	doge.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('doge').table
	doge.help = configuration.commandPrefix .. 'doge <text> - Doge-ifies the given text. Sentences are separated using slashes. Example: ' .. configuration.commandPrefix .. 'doge hello world\nthis is a test sentence\nmake sure you type like this\nelse it won\'t work!'
end

function doge:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, doge.help, nil, true, false, message.message_id) return end
	local url = 'http://dogr.io/' .. input:gsub(' ', '%%20'):gsub('\n', '/') .. '.png?split=false&.png'
	if not url:match('https?://[%%%w-_%.%?%.:/%+=&]+') == url then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	mattata.sendPhoto(message.chat.id, url)
end

return doge