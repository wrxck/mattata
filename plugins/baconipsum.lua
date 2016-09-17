local baconipsum = {}
local functions = require('functions')
local HTTPS = require('ssl.https')
function baconipsum:init(configuration)
	baconipsum.command = 'baconipsum'
	baconipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('baconipsum', true).table
	baconipsum.doc = configuration.command_prefix .. 'baconipsum - Generate a few meaty Lorem Ipsum sentences!'
end
function baconipsum:action(msg, configuration)
    local output = '`' HTTPS.request(configuration.baconipsum_api) '`'
    functions.send_reply(self, msg, output, true)
end
return baconipsum