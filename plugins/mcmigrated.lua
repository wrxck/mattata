local mcmigrated = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function mcmigrated:init(configuration)
	mcmigrated.arguments = 'mcmigrated <username>'
	mcmigrated.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mcmigrated').table
	mcmigrated.help = configuration.commandPrefix .. 'mcmigrated <username> - Tells you if a Minecraft username has been migrated to a Mojang account.'
end

function mcmigrated:onMessageReceive(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, mcmigrated.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://eu.mc-api.net/v3/migrated/' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local output
	if string.match(jstr, 'true') then
		output = 'This username has been migrated to a Mojang account!'
	else
		output = 'This username either does not exist, or it just hasn\'t been migrated to a Mojang account.'
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return mcmigrated