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
	local raw_joke = HTTP.request(configuration.chuck_api)
	local decoded_joke = JSON.decode(raw_joke)
	if decoded_joke.error then
		functions.send_reply(self, msg, configuration.errors.results)
		return
	end
	local output = '`' .. decoded_joke.value.joke .. '`'
	functions.send_reply(self, msg, output, true)
end
return chuck