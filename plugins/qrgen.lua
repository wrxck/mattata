local qrgen = {}
local mattata = require('mattata')
local URL = require('socket.url')

function qrgen:init(configuration)
	qrgen.arguments = 'qrgen <string>'
	qrgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('qrgen').table
	qrgen.help = configuration.commandPrefix .. 'qrgen - Converts the given string to an QR code.'
end

function qrgen:onMessageReceive(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, qrgen.help, nil, true, false, message.message_id)
		return
	end
	local res = mattata.sendPhoto(message.from.id, 'http://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=' .. URL.escape(input) .. '&chld=H|0.png', nil, false)
	if not res then
		mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', 'Markdown', true, false, message.message_id)
	else
		mattata.sendChatAction(message.from.id, 'upload_photo')
		mattata.sendMessage(message.chat.id, 'I have sent you your QR code via a private message.', nil, true, false, message.message_id)
	end
end

return qrgen