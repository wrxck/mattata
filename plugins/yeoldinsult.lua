local yeoldinsult = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function yeoldinsult:init(configuration)
	yeoldinsult.command = 'yeoldinsult'
	yeoldinsult.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('yeoldinsult', true).table
	yeoldinsult.documentation = configuration.command_prefix .. 'yeoldinsult - Insults you, the old-school way.' 
end
function yeoldinsult:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.yeoldinsult)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	functions.send_reply(msg, jdat.insult)
end
return yeoldinsult