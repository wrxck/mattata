local ninegag = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function ninegag:init(configuration)
	ninegag.command = '9gag'
	ninegag.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('9gag', true).table
	ninegag.doc = configuration.command_prefix .. '9gag - Returns a random result from the latest 9gag images.'
end
function ninegag:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.ninegag_api)
	if res ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection)
		return
	end
	local jstr = HTTP.request(configuration.ninegag_api)
	local jdat = JSON.decode(jstr)
	local random = jdat[math.random(#jdat)]
	local output = '[' .. random.title .. '](' .. random.src .. ')'
	functions.send_message(self, msg.chat.id, output, false, nil, true)
end
return ninegag