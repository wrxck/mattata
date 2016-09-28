local skateipsum = {}
local functions = require('functions')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function skateipsum:init(configuration)
	skateipsum.command = 'skateipsum'
	skateipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('skateipsum', true).table
	skateipsum.doc = configuration.command_prefix .. 'skateipsum - Generates a few skateboard-themed Lorem Ipsum sentences!'
end
function skateipsum:action(msg, configuration)
	local jdat = ''
	local jstr, res = HTTP.request(configuration.skateipsum_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		jdat = JSON.decode(jstr)
		output = jdat[1]
		functions.send_reply(msg, '`' .. output .. '`', true)
		return
	end
end
return skateipsum