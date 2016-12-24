local doggo = {}
local mattata = require('mattata')

function doggo:init(configuration)
	doggo.arguments = 'doggo'
	doggo.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('doggo').table
	doggo.help = configuration.commandPrefix .. 'doggo - Sends a cute lil\' doggo!'
end

function doggo:onMessage(message, configuration, language)
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local res = mattata.sendVideo(message.chat.id, 'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif')
	if not res then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) end
end

return doggo