local yomama = {}
local functions = require('functions')
local JSON = require('dkjson')
local HTTP = require('socket.http')
function yomama:init(configuration)
	yomama.command = 'yomama'
	yomama.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('yomama', true).table
	yomama.doc = configuration.command_prefix .. 'yomama - Tells a Yo\' Mama joke!'
end
function yomama:action(msg, configuration)
	local jdat = ''
	local output = ''
	local jstr, res = HTTP.request(configuration.yomama_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		jdat = JSON.decode(jstr)
		output = '`' .. jdat.joke .. '`'
		functions.send_reply(msg, output, true)
		return
	end
end
return yomama