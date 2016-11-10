local pwgen = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function pwgen:init(configuration)
	pwgen.arguments = 'pwgen <length>'
	pwgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pwgen').table
	pwgen.help = configuration.commandPrefix .. 'pwgen <length> - Generates a random password of the given length.'
end

function pwgen:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, pwgen.help, nil, true, false, message.message_id)
		return
	end
	if message.chat.type == 'private' then
		if tonumber(input) == nil or tonumber(input) > 4096 or tonumber(input) < 8 then
			mattata.sendMessage(message.chat.id, 'Please enter a value between 8 and 4096.', nil, true, false, message.message_id)
			return
		end
	else
		if tonumber(input) == nil or tonumber(input) > 4096 or tonumber(input) < 8 then
			mattata.sendMessage(message.chat.id, 'Please enter a value between 8 and 128.', nil, true, false, message.message_id)
			return
		end
	end
	local output = io.popen('python3 plugins/pwgen.py ' .. input):read('*all')
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
	return
end

return pwgen