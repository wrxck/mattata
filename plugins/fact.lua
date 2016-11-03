local fact = {}
local JSON = require('dkjson')
local mattata = require('mattata')
local HTTP = require('socket.http')

function fact:init(configuration)
	fact.arguments = 'fact'
	fact.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('fact').table
	fact.help = configuration.commandPrefix .. 'fact - Returns a random fact!'
end

function fact:onQueryReceive(callback, message, configuration)
	if callback.data == 'new_fact' then
		local jstr, res = HTTP.request(configuration.apis.fact)
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, configuration.errors.connection, nil, true, '{"inline_keyboard":[[{"text":"Try again", "callback_data":"new_fact"}]]}')
			return
		end
		local jdat = JSON.decode(jstr)
		local jrnd = math.random(#jdat)
		mattata.editMessageText(message.chat.id, message.message_id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_fact"}]]}')
	end
end

function fact:onMessageReceive(message, configuration)
	local jstr, res = HTTP.request(configuration.apis.fact)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	mattata.sendMessage(message.chat.id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, false, message.message_id, '{"inline_keyboard":[[{"text":"Generate another", "callback_data":"new_fact"}]]}')
end

return fact