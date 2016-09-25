local fact = {}
local JSON = require('dkjson')
local functions = require('functions')
local HTTP = require('socket.http')
function fact:init(configuration)
	fact.command = 'fact'
	fact.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('fact', true).table
	fact.doc = configuration.command_prefix .. 'fact - Returns a random fact!'
end
function fact:action(msg, configuration)
	local jstr, res = HTTP.request(configuration.fact_api)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection, true)
		return
	else
		local jdat = JSON.decode(jstr)
		local jrnd = math.random(#jdat)
		local output = '`' .. jdat[jrnd].nid:gsub('<p>',''):gsub('</p>',''):gsub('&amp;','&'):gsub('<em>',''):gsub('</em>',''):gsub('<strong>',''):gsub('</strong>','') .. '`'
		functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Generate a new fact!", "callback_data":"fact"}]]}')
		return
	end
end
return fact