local catfact = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function catfact:init(configuration)
	catfact.command = 'catfact'
	catfact.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('catfact', true).table
	catfact.doc = configuration.command_prefix .. 'catfact - A random cat-related fact!'
end
function catfact:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.catfact_api)
	local jdat = JSON.decode(jstr)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration,errors.connection .. '`', true)
		return
	end
	if jdat.error then
		functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
		return
	end
	local output = '`' .. jdat.facts[1] .. '`'
	functions.send_reply(msg, output:gsub('â', ' '), true)
end
return catfact