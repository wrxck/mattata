local HTTPS = require('ssl.https')
local functions = require('functions')
local rms = {}
function rms:init(configuration)
	rms.BASE_URL = 'https://rms.sexy/img/'
	rms.LIST = {}
	rms.STR = HTTPS.request(rms.BASE_URL)
	for link in rms.STR:gmatch('<a href=".-%.%a%a%a">(.-)</a>') do
		table.insert(rms.LIST, link)
	end
	rms.command = 'rms'
	rms.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('rms', true).table
end
function rms:action(msg, configuration)
	functions.send_action(msg.chat.id, 'upload_photo')
	local choice = rms.LIST[math.random(#rms.LIST)]
	functions.send_photo(msg.chat.id, functions.download_to_file(rms.BASE_URL .. choice))
end
return rms