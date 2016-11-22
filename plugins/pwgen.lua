local pwgen = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function pwgen:init(configuration)
	pwgen.arguments = 'pwgen <length>'
	pwgen.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pwgen').table
	pwgen.help = configuration.commandPrefix .. 'pwgen <length> - Generates a random password of the given length.'
end

function pwgen:onChannelPost(channel_post)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, pwgen.help, nil, true, false, channel_post.message_id)
		return
	end
	if tonumber(input) == nil or tonumber(input) > 4096 or tonumber(input) < 8 then
		mattata.sendMessage(channel_post.chat.id, 'Please enter a value between 8 and 4096.', nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, '```\n' .. io.popen('python3 plugins/pwgen.py ' .. input):read('*all') .. '\n```', 'Markdown', true, false, channel_post.message_id)
end

function pwgen:onMessage(message)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, pwgen.help, nil, true, false, message.message_id)
		return
	end
	if message.chat.type == 'private' and (tonumber(input) == nil or tonumber(input) > 4096 or tonumber(input) < 8) then
		mattata.sendMessage(message.chat.id, 'Please enter a value between 8 and 4096.', nil, true, false, message.message_id)
		return
	end
	if tonumber(input) == nil or tonumber(input) > 128 or tonumber(input) < 8 then
		mattata.sendMessage(message.chat.id, 'Please enter a value between 8 and 128.', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '```\n' .. io.popen('python3 plugins/pwgen.py ' .. input):read('*all') .. '\n```', 'Markdown', true, false, message.message_id)
end

return pwgen