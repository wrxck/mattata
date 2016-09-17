local yeoldinsult = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function yeoldinsult:init(configuration)
	yeoldinsult.command = 'yeoldinsult'
	yeoldinsult.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('yeoldinsult', true).table
	yeoldinsult.doc = configuration.command_prefix .. 'yeoldinsult - Insults you, the old-school way.' 
end
function yeoldinsult:action(msg, configuration)
	local url = HTTP.request(configuration.yeoldinsult_api)
	local raw = JSON.decode(url)
	local insult = '`' .. raw.insult .. '`'
	functions.send_reply(self, msg, insult, true)
end
return yeoldinsult