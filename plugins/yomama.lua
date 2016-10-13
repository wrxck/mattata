local yomama = {}
local functions = require('functions')
local JSON = require('dependencies.dkjson')
local HTTP = require('dependencies.socket.http')
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
	local jdat, output
	if string.match(jstr, 'Unable to connect to the database server.') then
		output = configuration.errors.connection
	else
		jdat = JSON.decode(jstr)
		output = jdat.joke
	end
	functions.send_reply(msg, output)
end
return yomama