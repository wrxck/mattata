local loremipsum = {}
local functions = require('functions')
local HTTP = require('dependencies.socket.http')
function loremipsum:init(configuration)
	loremipsum.command = 'loremipsum'
	loremipsum.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('loremipsum', true).table
	loremipsum.documentation = configuration.command_prefix .. 'loremipsum - Generates a few Lorem Ipsum sentences!'
end
function loremipsum:action(msg, configuration)
	local output, res = HTTP.request(configuration.apis.loremipsum)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	functions.send_reply(msg, output)
end
return loremipsum