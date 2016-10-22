local qrgen = {}
local URL = require('dependencies.socket.url')
local mattata = require('mattata')

function qrgen:init(configuration)
	qrgen.arguments = 'qrgen <string>'
	qrgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('qrgen', true).table
	qrgen.help = configuration.commandPrefix .. 'qrgen - Converts the given string to an QR code.'
end

function qrgen:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, qrgen.help, nil, true, false, msg.message_id, nil)
		return
	end
	local str = configuration.apis.qrgen .. URL.escape(input) .. '&chld=H|0'
	local res = mattata.sendPhoto(msg.from.id, str .. '.png', nil, false, msg.message_id, nil)
	if not res then
		mattata.sendMessage(msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', 'Markdown', true, false, msg.message_id, nil)
	else
		mattata.sendChatAction(msg.from.id, 'upload_photo')
		mattata.sendMessage(msg.chat.id, 'I have sent you your QR code via a private message.', nil, true, false, msg.message_id, nil)
	end
end

return qrgen