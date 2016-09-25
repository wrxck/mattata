local qrgen = {}
local URL = require('socket.url')
local functions = require('functions')
function qrgen:init(configuration)
	qrgen.command = 'qrgen <string>'
	qrgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('qrgen', true).table
	qrgen.doc = configuration.command_prefix .. 'qrgen - Converts the given string to an QR code.'
end
function qrgen:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, qrgen.doc, true)
		return
	end
	local str = configuration.qrgen_api .. URL.escape(input) .. '&chld=H|0'
	functions.send_action(msg.from.id, 'upload_photo')
	local res = functions.send_photo(msg.from.id, functions.download_to_file(str,  math.random(5000) .. '.png'), 'Here is your string, \'' .. input .. '\' - as a QR code.')
	if not res then
		if msg.chat.type ~= 'private' then
			functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the QR code.', true)
			return
		end
	elseif msg.chat.type ~= 'private' then
		functions.send_reply(msg, '`I sent you your QR code via private message.`', true)
		return
	end
end
return qrgen