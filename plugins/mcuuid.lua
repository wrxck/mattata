local mcuuid = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function mcuuid:init(configuration)
	mcuuid.arguments = 'mcuuid <Minecraft username>'
	mcuuid.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mcuuid').table
	mcuuid.help = configuration.commandPrefix .. 'mcuuid <Minecraft username> - Tells you the UUID of a Minecraft username.'
end

function mcuuid:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, mcuuid.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://mcapi.ca/uuid/player/' .. input)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if string.len(jdat[1].uuid_formatted) < 36 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, '```\n' .. jdat[1].uuid_formatted .. '\n```', 'Markdown', true, false, channel_post.message_id)
end

function mcuuid:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, mcuuid.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://mcapi.ca/uuid/player/' .. input)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if string.len(jdat[1].uuid_formatted) < 36 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '```\n' .. jdat[1].uuid_formatted .. '\n```', 'Markdown', true, false, message.message_id)
end

return mcuuid