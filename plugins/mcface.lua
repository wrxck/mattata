local mcface = {}
local HTTPS = require('ssl.https')
local functions = require('functions')
local telegram_api = require('telegram_api')
function mcface:init(configuration)
	mcface.command = 'mcface <Minecraft username>'
	mcface.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcface', true).table
	mcface.documentation = configuration.command_prefix .. 'mcface <Minecraft username> - Sends the face of the given Minecraft player\'s skin.'
end
function mcface:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mcface.documentation)
		return
	end
	local jstr, res = HTTPS.request(configuration.apis.mcface.uuid .. input)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local str = configuration.apis.mcface.avatar .. input .. '/100.png'
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	functions.send_photo(msg.chat.id, functions.download_to_file(str), input, msg.message_id)
end
return mcface