local yomama = {}
local functions = require('functions')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function yomama:init(configuration)
	yomama.command = 'yomama'
	yomama.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('yomama', true).table
	yomama.documentation = configuration.command_prefix .. 'yomama - Tells a Yo\' Mama joke!'
end
function yomama:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.yomama)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, jdat.joke)
end
return yomama