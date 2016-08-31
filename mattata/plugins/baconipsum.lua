local baconipsum = {}
local functions = require('mattata.functions')
local HTTPS = require('ssl.https')
function baconipsum:init(configuration)
	baconipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('baconipsum', true).table
	baconipsum.command = 'baconipsum'
	baconipsum.doc = 'Generate a few meaty Lorem Ipsum sentences!'
end
function baconipsum:action(msg, configuration)
    local api = configuration.baconipsum_api
    local output = HTTPS.request(api)
    functions.send_message(self, msg.chat.id, output, nil, true)
end
return baconipsum
