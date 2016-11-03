local shout = {}
local mattata = require('mattata')

function shout:init(configuration)
    shout.arguments = 'shout <text>'
    shout.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('shout').table
    shout.help = configuration.commandPrefix .. 'shout <text> - Shout something.'
end

function shout:onMessageReceive(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, shout.help, nil, true, false, message.message_id, nil)
		return
	end
	input = mattata.trim(input)
	input = input:upper()
	local output = ''
	local inc = 0
	local len = 0
	for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if len < 20 then
			len = len + 1
			output = output .. match .. ' '
		end
	end
	len = 0
	output = output .. '\n'
	for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if len < 19 then
			local space = ''
			for _ = 1, inc do
				space = space .. '  '
			end
			inc = inc + 1
			len = len + 1
			output = output .. match .. ' ' .. space .. match .. '\n'
		end
	end
	output = '```\n' .. mattata.trim(output) .. '\n```'
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
end

return shout