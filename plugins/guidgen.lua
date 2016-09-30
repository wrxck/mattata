local guidgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function guidgen:init(configuration)
	guidgen.command = 'guidgen'
	guidgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('guidgen', true).table
	guidgen.documentation = configuration.command_prefix .. 'guidgen - Generates a random GUID.'
end
function guidgen:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.guidgen)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, jdat.char[1])
end
return guidgen