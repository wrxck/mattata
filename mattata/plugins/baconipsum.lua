local baconipsum = {}
local utilities = require('mattata.utilities')
local HTTPS = require('ssl.https')
function baconipsum:init(config)
	baconipsum.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('baconipsum', true).table
baconipsum.command = 'baconipsum'
baconipsum.doc = 'Generates a few meaty Lorem Ipsum sentences!'
end
function baconipsum:action(msg, config)
 local url = 'https://baconipsum.com/api/?type=all-meat&sentences=3&start-with-lorem=1&format=text'
 local output = HTTPS.request(url)
	utilities.send_message(self, msg.chat.id, output, nil, true)
end
return baconipsum
