local identicon = {}
local URL = require('socket.url')
local mattata = require('mattata')

function identicon:init(configuration)
	identicon.arguments = 'identicon <string>'
	identicon.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('identicon').table
	identicon.help = configuration.commandPrefix .. 'identicon <string> - Converts the given string to an identicon.'
end

function identicon:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, identicon.help, nil, true, false, message.message_id, nil)
		return
	end
	local str = configuration.apis.identicon .. URL.escape(input) .. '.png'
	local res = mattata.sendPhoto(message.from.id, str, nil, false, nil, nil)
	if not res then
		mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, false, message.message_id, nil)
	elseif message.chat.type ~= 'private' then
		mattata.sendMessage(message.chat.id, 'I have sent you a private message containing the requested information.', nil, true, false, message.message_id, nil)
	end
end

return identicon