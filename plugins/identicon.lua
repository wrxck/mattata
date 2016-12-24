local identicon = {}
local mattata = require('mattata')
local url = require('socket.url')

function identicon:init(configuration)
	identicon.arguments = 'identicon <string>'
	identicon.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('identicon').table
	identicon.help = configuration.commandPrefix .. 'identicon <string> - Converts the given string of text to an identicon.'
end

function identicon:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, identicon.help, nil, true, false, message.message_id); return end
	local res = mattata.sendPhoto(message.from.id, 'http://identicon.rmhdev.net/' .. url.escape(input) .. '.png', nil, false)
	if not res then mattata.sendMessage(message.chat.id, language.pleaseMessageMe:gsub('MATTATA', self.info.username), 'Markdown', true, false, message.message_id);
	elseif message.chat.type ~= 'private' then mattata.sendMessage(message.chat.id, language.sentPrivateMessage, nil, true, false, message.message_id) end
end

return identicon