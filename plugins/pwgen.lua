local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function pwgen:init(configuration)
	pwgen.arguments = 'pwgen <length>'
	pwgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pwgen', true).table
	pwgen.help = configuration.commandPrefix .. 'pwgen <length> - Generates a random password of the given length.'
end

function pwgen:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, pwgen.help, nil, true, false, msg.message_id, nil)
		return
	end
	if tonumber(input) ~= nil then
		if tonumber(input) > 30 then
			mattata.sendMessage(msg.chat.id, '`Please enter a lower number.', nil, true, false, msg.message_id, nil)
			return
		end
		if tonumber(input) < 5 then
			mattata.sendMessage(msg.chat.id, 'Please enter a higher number.', nil, true, false, msg.message_id, nil)
			return 
		end
		local jstr, res = HTTP.request(configuration.apis.pwgen .. input)
		if res ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		end
		local jdat = JSON.decode(jstr)
		mattata.sendMessage(msg.chat.id, '*Password:* `' .. mattata.markdownEscape(jdat[1].password) .. '`\n*Phonetic:* `' .. mattata.markdownEscape(jdat[1].phonetic) .. '`', 'Markdown', true, false, msg.message_id, nil)
		return
	else
		mattata.sendMessage(msg.chat.id, 'Please enter a numeric value.', nil, true, false, msg.message_id, nil)
		return
	end
end

return pwgen