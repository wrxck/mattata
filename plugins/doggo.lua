local doggo = {}
local mattata = require('mattata')

function doggo:init(configuration)
	doggo.arguments = 'doggo'
	doggo.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('doggo', true).table
	doggo.help = configuration.commandPrefix .. 'doggo - Sends a cute lil\' doggo.'
end

function doggo:onMessageReceive(msg, configuration)
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	mattata.sendVideo(msg.chat.id, 'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif')
end

return doggo
