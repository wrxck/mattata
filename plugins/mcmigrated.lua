local mcmigrated = {}
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function mcmigrated:init(configuration)
	mcmigrated.arguments = 'mcmigrated <username>'
	mcmigrated.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mcmigrated', true).table
	mcmigrated.help = configuration.commandPrefix .. 'mcmigrated <username> - Tells you if a Minecraft username has been migrated to a Mojang account.'
end

function mcmigrated:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, mcmigrated.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.mcmigrated .. input
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local output = ''
	if string.match(jstr, 'true') then
		output = 'This username has been migrated to a Mojang account!'
	else
		output = 'This username either does not exist, or it just hasn\'t been migrated to a Mojang account.'
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return mcmigrated