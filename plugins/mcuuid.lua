local mcuuid = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local functions = require('functions')
function mcuuid:init(configuration)
	mcuuid.command = 'mcuuid <Minecraft username>'
	mcuuid.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcuuid', true).table
	mcuuid.documentation = configuration.command_prefix .. 'mcuuid <Minecraft username> - Tells you the UUID of a Minecraft username.'
end
function mcuuid:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mcuuid.documentation)
		return
	end
	local url = configuration.apis.mcuuid .. input
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = jdat[1].uuid_formatted
	if string.len(output) < 36 then
		output = 'The given username is inexistent.'
	else
		output = output
	end
	functions.send_reply(msg, output)
end
return mcuuid