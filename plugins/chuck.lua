local chuck = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function chuck:init(configuration)
	chuck.command = 'chuck'
	chuck.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('chuck', true).table
	chuck.doc = configuration.command_prefix .. 'chuck - Generates a Chuck Norris joke!'
end
function chuck:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.chuck_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		local jdat = JSON.decode(jstr)
		if jdat.error then
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
			return
		end
		local output = '`' .. functions.html_escape(jdat.value.joke) .. '`'
		functions.send_reply(msg, output, true)
	end
end
return chuck