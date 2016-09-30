local skateipsum = {}
local functions = require('functions')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function skateipsum:init(configuration)
	skateipsum.command = 'skateipsum'
	skateipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('skateipsum', true).table
	skateipsum.documentation = configuration.command_prefix .. 'skateipsum - Generates a few skateboard-themed Lorem Ipsum sentences!'
end
function skateipsum:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.skateipsum)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, jdat[1])
end
return skateipsum