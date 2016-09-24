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
	if not input then
		functions.send_reply(msg, mcmigrated.doc, true)
		return
	else
		local jstr, res = HTTPS.request(configuration.mchistory_uuid_api .. input)
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		else
			local jdat = JSON.decode(jstr)
			local output = '`' .. HTTPS.request(configuration.mchistory_api .. jdat.id .. '/names') .. '`'
			functions.send_reply(msg, output, true)
			return
		end
	end
end
return mchistory