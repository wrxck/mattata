local shorten = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function shorten:init(configuration)
	shorten.arguments = 'shorten <URL>'
	shorten.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('shorten').table
	shorten.help = configuration.commandPrefix .. 'shorten - Shortens the given URL.'
end

function shorten:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, shorten.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://hec.su/api?url=' .. input)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	elseif string.match(jstr, 'Invalid URL') then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(channel_post.chat.id, jdat.short, nil, true, false, channel_post.message_id)
end

function shorten:onMessageReceive(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, shorten.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://hec.su/api?url=' .. input)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	elseif string.match(jstr, 'Invalid URL') then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	mattata.sendMessage(message.chat.id, jdat.short, nil, true, false, message.message_id)
end

return shorten