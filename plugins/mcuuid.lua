local mcuuid = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function mcuuid:init(configuration)
	mcuuid.command = 'mcuuid <Minecraft username>'
	mcuuid.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('mcuuid', true).table
	mcuuid.doc = configuration.command_prefix .. 'mcuuid <Minecraft username> - Tells you the UUID of a Minecraft username.'
end
function mcuuid:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, mcuuid.doc, true)
		return
	else
		local url = configuration.mcuuid_api .. input
		local jstr, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		else
			local jdat = JSON.decode(jstr)
			functions.send_reply(msg, '`' .. jdat[1].uuid_formatted .. '`', true)
			return
		end
	end
end
return mcuuid