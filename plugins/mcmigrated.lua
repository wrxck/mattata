local mcmigrated = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
function mcmigrated:init(configuration)
	mcmigrated.command = 'mcmigrated <username>'
	mcmigrated.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcmigrated', true).table
	mcmigrated.doc = configuration.command_prefix .. 'mcmigrated <username> - Tells you if a Minecraft username has been migrated to a Mojang account.'
end
function mcmigrated:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mcmigrated.doc, true)
		return
	else
		local url = configuration.mcmigrated_api .. input
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		else
			local jdat = JSON.decode(jstr)
			local output = jdat.migrated:gsub('true', '`This username has been migrated to a Mojang account!`'):gsub('false', '`This username has not been migrated to a Mojang account...`')
			functions.send_reply(msg, output, true)
			return
		end
	end
end
return mcmigrated