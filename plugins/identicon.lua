local identicon = {}
local URL = require('socket.url')
local mattata = require('mattata')

function identicon:init(configuration)
	identicon.arguments = 'identicon <string>'
	identicon.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('identicon').table
	identicon.help = configuration.commandPrefix .. 'identicon - Converts the given string to an identicon.'
end

function identicon:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, identicon.help, nil, true, false, msg.message_id, nil)
		return
	end
	local str = configuration.apis.identicon .. URL.escape(input) .. '.png'
	local res = mattata.sendPhoto(msg.from.id, str, nil, false, nil, nil)
	if not res then
		mattata.sendMessage(msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, false, msg.message_id, nil)
	elseif msg.chat.type ~= 'private' then
		mattata.sendMessage(msg.chat.id, 'I have sent you a private message containing the requested information.', nil, true, false, msg.message_id, nil)
	end
end

return identicon