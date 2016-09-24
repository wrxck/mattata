local guidgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function guidgen:init(configuration)
	guidgen.command = 'guidgen'
	guidgen.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('guidgen', true).table
	guidgen.doc = configuration.command_prefix .. 'guidgen - Generates a random GUID.'
end
function guidgen:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.guidgen_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		local jdat = JSON.decode(jstr)
		local output = '`' .. jdat.char[1] .. '`'
		functions.send_reply(msg, output, true)
		return
	end
end
return guidgen