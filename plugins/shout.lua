local shout = {}
local mattata = require('mattata')

function shout:init(configuration)
    shout.arguments = 'shout <text>'
    shout.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('shout').table
    shout.help = configuration.commandPrefix .. 'shout <text> - Shout something.'
end

function shout:onChannelPostReceive(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, shout.help, nil, true, false, channel_post.message_id)
		return
	end
	input = mattata.trim(input)
	input = input:upper()
	local output = ''
	local increment = 0
	local length = 0
	for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if length < 20 then
			length = length + 1
			output = output .. match .. ' '
		end
	end
	length = 0
	output = output .. '\n'
	for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if length < 19 then
			local space = ''
			for _ = 1, increment do
				space = space .. '  '
			end
			increment = increment + 1
			length = length + 1
			output = output .. match .. ' ' .. space .. match .. '\n'
		end
	end
	output = '```\n' .. mattata.trim(output) .. '\n```'
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id)
end

function shout:onMessageReceive(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, shout.help, nil, true, false, message.message_id)
		return
	end
	input = mattata.trim(input)
	input = input:upper()
	local output = ''
	local increment = 0
	local length = 0
	for match in input:gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if length < 20 then
			length = length + 1
			output = output .. match .. ' '
		end
	end
	length = 0
	output = output .. '\n'
	for match in input:sub(2):gmatch('([%z\1-\127\194-\244][\128-\191]*)') do
		if length < 19 then
			local space = ''
			for _ = 1, increment do
				space = space .. '  '
			end
			increment = increment + 1
			length = length + 1
			output = output .. match .. ' ' .. space .. match .. '\n'
		end
	end
	output = '```\n' .. mattata.trim(output) .. '\n```'
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return shout