local fact = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function fact:init(configuration)
	fact.command = 'fact'
	fact.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('fact', true).table
	fact.documentation = configuration.command_prefix .. 'fact - Returns a random fact!'
end
function fact:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.fact)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	functions.send_reply(msg, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), false, '{"inline_keyboard":[[{"text":"Generate a new fact!", "callback_data":"fact"}]]}')
end
return fact