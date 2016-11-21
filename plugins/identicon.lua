local identicon = {}
local URL = require('socket.url')
local mattata = require('mattata')

function identicon:init(configuration)
	identicon.arguments = 'identicon <string>'
	identicon.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('identicon').table
	identicon.help = configuration.commandPrefix .. 'identicon <string> - Converts the given string to an identicon.'
end

function identicon:onMessageReceive(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, identicon.help, nil, true, false, message.message_id)
		return
	end
	local res = mattata.sendPhoto(message.from.id, 'http://identicon.rmhdev.net/' .. URL.escape(input) .. '.png', nil, false)
	if not res then
		mattata.sendMessage(message.chat.id, language.pleaseMessageMe:gsub('MATTATA', self.info.username), 'Markdown', true, false, message.message_id)
	elseif message.chat.type ~= 'private' then
		mattata.sendMessage(message.chat.id, language.sentPrivateMessage, nil, true, false, message.message_id)
	end
end

return identicon