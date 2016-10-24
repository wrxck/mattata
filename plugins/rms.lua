local rms = {}
local HTTPS = require('dependencies.ssl.https')
local mattata = require('mattata')

function rms:init(configuration)
	rms.list = {}
	rms.str = HTTPS.request('http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/')
	for link in rms.str:gmatch('<a href=".-%.%a%a%a">(.-).gif</a>') do
		table.insert(rms.list, link)
	end
	rms.arguments = 'rms'
	rms.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('rms', true).table
	rms.help = configuration.commandPrefix .. 'rms - Sends a photo of Dr. Richard Stallman.'
end

function rms:onMessageReceive(msg, configuration)
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	local choice = rms.list[math.random(#rms.list)]
	mattata.sendVideo(msg.chat.id, 'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif')
end

return rms