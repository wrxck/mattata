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
	local jdat = ''
	local output = ''
	local jstr, res = HTTP.request(configuration.yeoldinsult_api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		jdat = JSON.decode(jstr)
		output = '`' .. jdat.insult .. '`'
		functions.send_reply(msg, output, true)
		return
	end
end
return yeoldinsult