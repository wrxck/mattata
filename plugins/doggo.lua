-- For @Floofy_Fox

local doggo = {}
local mattata = require('mattata')

function doggo:init(configuration)
	doggo.arguments = 'doggo'
	doggo.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('doggo').table
	doggo.help = configuration.commandPrefix .. 'doggo - Sends a cute lil\' doggo.'
end

function doggo:onChannelPostReceive(channel_post)
	mattata.sendVideo(channel_post.chat.id, 'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif')
end

function doggo:onMessageReceive(message)
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendVideo(message.chat.id, 'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif')
end

return doggo
