local identicon = {}
local URL = require('socket.url')
local functions = require('functions')
local telegram_api = require('telegram_api')
function identicon:init(configuration)
	identicon.command = 'identicon <string>'
	identicon.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('identicon', true).table
	identicon.documentation = configuration.command_prefix .. 'identicon - Converts the given string to an identicon.'
end
function identicon:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, identicon.documentation)
		return
	end
	local str = configuration.apis.identicon .. URL.escape(input) .. '.png'
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	functions.send_photo(msg.chat.id, functions.download_to_file(str), 'Here is your string, \'' .. input .. '\' - as an identicon.')
end
return identicon
