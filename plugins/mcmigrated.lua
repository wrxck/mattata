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
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_reply(self, msg, mcmigrated.doc, true)
			return
		end
	end
	local url = configuration.mcmigrated_api .. input
	local jstr = HTTPS.request(url)
	local jdat = JSON.decode(jstr)
	local output = jdat.migrated:gsub('true', '`This username has been migrated to a Mojang account!`'):gsub('false', '`This username has not been migrated to a Mojang account...`')
	functions.send_reply(self, msg, output)
end
return mcmigrated