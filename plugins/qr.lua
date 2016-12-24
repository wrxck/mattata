local qr = {}
local mattata = require('mattata')
local url = require('socket.url')

function qr:init(configuration)
	qr.arguments = 'qr <string>'
	qr.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('qr').table
	qr.help = configuration.commandPrefix .. 'qr <string> - Converts the given string to an QR code.'
end

function qr:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, qr.help, nil, true, false, message.message_id)
		return
	end
	local res = mattata.sendPhoto(message.from.id, 'http://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=' .. url.escape(input) .. '&chld=H|0.png', nil, false)
	if not res then
		mattata.sendMessage(message.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', 'Markdown', true, false, message.message_id)
	else
		mattata.sendChatAction(message.from.id, 'upload_photo')
		mattata.sendMessage(message.chat.id, 'I have sent you your QR code via a private message.', nil, true, false, message.message_id)
	end
end

return qr