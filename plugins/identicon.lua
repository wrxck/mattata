local identicon = {}
local URL = require('dependencies.socket.url')
local mattata = require('mattata')

function identicon:init(configuration)
	identicon.arguments = 'identicon <string>'
	identicon.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('identicon', true).table
	identicon.help = configuration.commandPrefix .. 'identicon - Converts the given string to an identicon.'
end

function identicon:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, identicon.help, nil, true, false, msg.message_id, nil)
		return
	end
	local str = configuration.apis.identicon .. URL.escape(input) .. '.png'
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	mattata.sendPhoto(msg.chat.id, str, nil, false, msg.message_id, nil)
end

return identicon