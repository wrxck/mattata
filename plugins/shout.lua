local shout = {}
local mattata = require('mattata')

function shout:init(configuration)
    shout.arguments = 'shout <text>'
    shout.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('shout').table
    shout.help = configuration.commandPrefix .. 'shout <text> - Shout something.'
end

function shout:onMessage(message)
	local input = mattata.input(message.text_upper)
	if not input then mattata.sendMessage(message.chat.id, shout.help, nil, true, false, message.message_id) return end
	input = mattata.trim(input)
	local output = ''
	local increment = 0
	local length = 0
	for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)') do if length < 20 then length = length + 1; output = output .. match .. ' ' end; end
	length = 0
	output = output .. '\n'
	for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if length < 19 then
			local space = ''
			for _ = 1, increment do space = space .. '  ' end
			increment = increment + 1
			length = length + 1
			output = output .. match .. ' ' .. space .. match .. '\n'
		end
	end
	mattata.sendMessage(message.chat.id, '<pre>' .. mattata.trim(output) .. '</pre>', 'HTML', true, false, message.message_id)
end

return shout