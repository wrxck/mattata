local fact = {}
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')
local HTTP = require('dependencies.socket.http')

function fact:init(configuration)
	fact.arguments = 'fact'
	fact.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('fact', true).table
	fact.help = configuration.commandPrefix .. 'fact - Returns a random fact!'
end

function fact:onMessageReceive(msg, configuration)
	local jstr, res = HTTP.request(configuration.apis.fact)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	mattata.sendMessage(msg.chat.id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Generate a new fact!", "callback_data":"fact"}]]}')
end

return fact