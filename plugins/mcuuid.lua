local mcuuid = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function mcuuid:init(configuration)
	mcuuid.arguments = 'mcuuid <Minecraft username>'
	mcuuid.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mcuuid').table
	mcuuid.help = configuration.commandPrefix .. 'mcuuid <Minecraft username> - Tells you the UUID of a Minecraft username.'
end

function mcuuid:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, mcuuid.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.mcuuid .. input
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = jdat[1].uuid_formatted
	if string.len(output) < 36 then
		output = 'The given username is inexistent.'
	else
		output = output
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
end

return mcuuid