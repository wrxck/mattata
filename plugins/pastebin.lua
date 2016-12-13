local pastebin = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local multipart = require('multipart-post')
local ltn12 = require('ltn12')
local JSON = require('dkjson')

function pastebin:init(configuration)
	pastebin.arguments = 'pastebin <text>'
	pastebin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pastebin'):c('pb').table
	pastebin.help = configuration.commandPrefix .. 'pastebin <text> - Uploads the given snippet of text to pastebin and returns the link. Alias: ' .. configuration.commandPrefix .. 'pb.'
end

function pastebin.getUrl(str)
	local configuration = require('configuration')
	local parameters = {
		api_dev_key = configuration.keys.pastebin,
		api_option = 'paste',
		api_paste_code = str,
		api_paste_private = 0
	}
	for k, v in pairs(parameters) do
		parameters[k] = tostring(v)
	end
	local response = {}
	local body, boundary = multipart.encode(parameters)
	local jstr, res = HTTP.request{
		url = 'http://pastebin.com/api/api_post.php',
		method = 'POST',
		headers = {
			['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
			['Content-Length'] = #body,
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	}
	local jdat = table.concat(response)
	if not jdat or not jdat:match('^http://pastebin%.com/') then
		return false
	end
	return jdat
end

function pastebin:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, pastebin.help, nil, true, false, channel_post.message_id)
		return
	end
	local output = pastebin.getUrl(input)
	if not output then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, output, nil, true, false, channel_post.message_id)
end

function pastebin:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, pastebin.help, nil, true, false, message.message_id)
		return
	end
	local output = pastebin.getUrl(input)
	if not output then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return pastebin