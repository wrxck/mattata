local identicon = {}
local URL = require('socket.url')
local functions = require('functions')
function identicon:init(configuration)
	identicon.command = 'identicon <string>'
	identicon.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('identicon', true).table
	identicon.doc = configuration.command_prefix .. 'identicon - Converts the given string to an identicon.'
end
function identicon:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, identicon.doc, true)
		return
	end
	local str = configuration.identicon_api .. URL.escape(input) .. '.png'
	functions.send_action(msg.from.id, 'upload_photo')
	local res = functions.send_photo(msg.from.id, functions.download_to_file(str), 'Here is your string, \'' .. input .. '\' - as an identicon.')
	if not res then
		if msg.chat.type ~= 'private' then
			functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. ') so I can send you the identicon.', true)
			return
		end
	elseif msg.chat.type ~= 'private' then
		functions.send_reply(msg, '`I sent you your identicon via a private message.`', true)
		return
	end
end
return identicon