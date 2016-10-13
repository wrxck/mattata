local rms = {}
local HTTPS = require('dependencies.ssl.https')
local functions = require('functions')
function rms:init(configuration)
	rms.list = {}
	rms.str = HTTPS.request(configuration.apis.rms)
	for link in rms.str:gmatch('<a href=".-%.%a%a%a">(.-)</a>') do
		table.insert(rms.list, link)
	end
	rms.command = 'rms'
	rms.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('rms', true).table
	rms.documentation = configuration.command_prefix .. 'rms - Sends a photo of Dr. Richard Stallman.'
end
function rms:action(msg, configuration)
	functions.send_action(msg.chat.id, 'upload_photo')
	local choice = rms.list[math.random(#rms.list)]
	functions.send_photo(msg.chat.id, functions.download_to_file(configuration.apis.rms .. choice))
end
return rms