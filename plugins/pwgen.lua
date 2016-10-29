local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function pwgen:init(configuration)
	pwgen.arguments = 'pwgen <length>'
	pwgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pwgen').table
	pwgen.help = configuration.commandPrefix .. 'pwgen <length> - Generates a random password of the given length.'
end

function pwgen:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, pwgen.help, nil, true, false, msg.message_id, nil)
		return
	end
	if tonumber(input) == nil then
		mattata.sendMessage(msg.chat.id, 'Please enter a numeric value.', nil, true, false, msg.message_id, nil)
		return
	end
	if tonumber(input) > 24 or tonumber(input) < 8 then
		mattata.sendMessage(msg.chat.id, 'Please enter a value lower than 24 but greater than 8.', nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTP.request(configuration.apis.pwgen .. input)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(msg.chat.id, '*Password:* ' .. mattata.markdownEscape(jdat[1].password) .. '\n*Phonetic:* ' .. mattata.markdownEscape(jdat[1].phonetic), 'Markdown', true, false, msg.message_id, nil)
	return
end

return pwgen