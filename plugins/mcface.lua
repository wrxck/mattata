local mcface = {}
local HTTPS = require('ssl.https')
local mattata = require('mattata')

function mcface:init(configuration)
	mcface.arguments = 'mcface <Minecraft username>'
	mcface.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mcface').table
	mcface.help = configuration.commandPrefix .. 'mcface <Minecraft username> - Sends the face of the given Minecraft player\'s skin.'
end

function mcface:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, mcface.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request(configuration.apis.mcface.uuid .. input)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local str = configuration.apis.mcface.avatar .. input .. '/100.png'
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	local output = mattata.sendPhoto(msg.chat.id, str, nil, false, msg.message_id, nil)
	if not output then
		mattata.sendMessage(msg.chat.id, 'Would you like sauce with your McFace?', nil, true, false, msg.message_id, nil)
		return
	end
end

return mcface