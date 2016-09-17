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
	local url = HTTP.request(configuration.yomama_api)
	local raw = JSON.decode(url)
	local output = '`' .. raw.joke .. '`'
	functions.send_reply(self, msg, output, true)
end
return yomama