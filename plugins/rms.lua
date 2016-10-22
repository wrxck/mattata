local rms = {}
local HTTPS = require('dependencies.ssl.https')
local mattata = require('mattata')

function rms:init(configuration)
	rms.list = {}
	rms.str = HTTPS.request(configuration.apis.rms)
	for link in rms.str:gmatch('<a href=".-%.%a%a%a">(.-)</a>') do
		table.insert(rms.list, link)
	end
	rms.arguments = 'rms'
	rms.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('rms', true).table
	rms.help = configuration.commandPrefix .. 'rms - Sends a photo of Dr. Richard Stallman.'
end

function rms:onMessageReceive(msg, configuration)
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	local choice = rms.list[math.random(#rms.list)]
	mattata.sendPhoto(msg.chat.id, configuration.apis.rms .. choice, nil, false, msg.message_id, nil)
end

return rms