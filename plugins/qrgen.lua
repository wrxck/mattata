local qrgen = {}
local URL = require('socket.url')
local functions = require('functions')
local telegram_api = require('telegram_api')
function qrgen:init(configuration)
	qrgen.command = 'qrgen <string>'
	qrgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('qrgen', true).table
	qrgen.documentation = configuration.command_prefix .. 'qrgen - Converts the given string to an QR code.'
end
function qrgen:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, qrgen.documentation)
		return
	end
	local str = configuration.apis.qrgen .. URL.escape(input) .. '&chld=H|0'
	telegram_api.sendChatAction{ chat_id = msg.from.id, action = 'upload_photo' }
	local res = functions.send_photo(msg.from.id, functions.download_to_file(str,  math.random(5000) .. '.png'), 'Here is your string, \'' .. input .. '\' - as a QR code.')
	if not res then
		functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', true)
	else
		functions.send_reply(msg, 'I have sent you your QR code via a private message.')
	end
end
return qrgen