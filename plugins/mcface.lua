local mcface = {}
local HTTPS = require('ssl.https')
local functions = require('functions')
function mcface:init(configuration)
	mcface.command = 'mcface <Minecraft username>'
	mcface.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcface', true).table
	mcface.doc = configuration.command_prefix .. 'mcface <Minecraft username> - Sends the face of the given Minecraft player\'s skin.'
end
function mcface:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mcface.doc, true)
		return
	else
		local jstr, res = HTTPS.request(configuration.mcface_uuid_api .. input)
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
			return
		else
			local str = configuration.mcface_api .. input .. '/100.png'
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(str), input, msg.message_id)
			return
		end
	end
end
return mcface