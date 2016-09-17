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
	local url = configuration.guidgen_api
	local guid = HTTP.request(url)
	local jstr = JSON.decode(guid)
	functions.send_reply(self, msg, '`' .. jstr.char[1] .. '`', true)
end
return guidgen