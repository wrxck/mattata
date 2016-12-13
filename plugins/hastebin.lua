local hastebin = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local ltn12 = require('ltn12')
local JSON = require('dkjson')

function hastebin:init(configuration)
	hastebin.arguments = 'hastebin <code>'
	hastebin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('hastebin'):c('hb').table
	hastebin.help = configuration.commandPrefix .. 'hastebin <code> - Uploads the given snippet of code to Hastebin and returns the link. Alias: ' .. configuration.commandPrefix .. 'hb.'
end

function hastebin.getUrl(str)
	local response = {}
	local jstr, res, headers, code = HTTP.request({
		url = 'http://hastebin.com/documents',
		method = 'POST',
		headers = {
			['Accept'] = 'application/json',
			['Content-Length'] = str:len()
		},
		source = ltn12.source.string(str),
		sink = ltn12.sink.table(response)
	})
	if res ~= 200 or code ~= 'HTTP/1.1 200 OK' then
		return false
	end
	local jdat = JSON.decode(table.concat(response))
	if not jdat or not jdat.key then
		return false
	end
	return 'http://hastebin.com/' .. jdat.key
end

function hastebin:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, hastebin.help, nil, true, false, channel_post.message_id)
		return
	end
	local output = hastebin.getUrl(input)
	if not output then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, output, nil, true, false, channel_post.message_id)
end

function hastebin:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, hastebin.help, nil, true, false, message.message_id)
		return
	end
	local output = hastebin.getUrl(input)
	if not output then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return hastebin