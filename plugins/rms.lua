local HTTPS = require('ssl.https')
local functions = require('functions')
local telegram_api = require('telegram_api')
local rms = {}
function rms:init(configuration)
	rms.url = 'https://rms.sexy/img/'
	rms.list = {}
	rms.str = HTTPS.request(rms.url)
	for link in rms.str:gmatch('<a href=".-%.%a%a%a">(.-)</a>') do
		table.insert(rms.list, link)
	end
	rms.command = 'rms'
	rms.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('rms', true).table
	rms.documentation = configuration.command_prefix .. 'rms - Sends a photo of Dr. Richard.'
end
function rms:action(msg, configuration)
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	local choice = rms.list[math.random(#rms.list)]
	functions.send_photo(msg.chat.id, functions.download_to_file(rms.url .. choice))
end
return rms