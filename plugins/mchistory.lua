local mchistory = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
function mchistory:init(configuration)
	mchistory.command = 'mchistory <Minecraft username>'
	mchistory.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mchistory', true).table
	mchistory.doc = configuration.command_prefix .. 'mchistory <Minecraft username> - Returns the name history of a Minecraft username.'
end
function mchistory:action(msg, configuration)
	local input = functions.input(msg.text)
	local uuid = HTTPS.request(configuration.mchistory_uuid_api .. input)
	local uuid_output = JSON.decode(uuid)
	local history = HTTPS.request(configuration.mchistory_api .. uuid_output.id .. '/names')
	functions.send_reply(self, msg, '`' .. history .. '`', true)
end
return mchistory