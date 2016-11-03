local qrgen = {}
local URL = require('socket.url')
local mattata = require('mattata')

function qrgen:init(configuration)
	qrgen.arguments = 'qrgen <string>'
	qrgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('qrgen').table
	qrgen.help = configuration.commandPrefix .. 'qrgen - Converts the given string to an QR code.'
end

function qrgen:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, qrgen.help, nil, true, false, message.message_id, nil)
		return
	end
	local str = configuration.apis.qrgen .. URL.escape(input) .. '&chld=H|0'
	local res = mattata.sendPhoto(message.from.id, str .. '.png', nil, false, message.message_id, nil)
	if not res then
		mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', 'Markdown', true, false, message.message_id, nil)
	else
		mattata.sendChatAction(message.from.id, 'upload_photo')
		mattata.sendMessage(message.chat.id, 'I have sent you your QR code via a private message.', nil, true, false, message.message_id, nil)
	end
end

return qrgen