local twitch = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function twitch:init(configuration)
	twitch.arguments = 'twitch <query>'
	twitch.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('twitch').table
	twitch.help = configuration.commandPrefix .. 'twitch <query> - Searches Twitch for a stream matching the given query.'
end

function twitch:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, twitch.help, nil, true, false, channel_post.message_id)
		return
	end
	local limit = 4
	local jstr, res = HTTPS.request('https://api.twitch.tv/kraken/search/streams?q=' .. URL.escape(input) .. '&client_id=' .. configuration.keys.twitch .. '&limit=' .. limit)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat._total == 0 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	if #jdat.streams < limit then
		limit = #jdat.streams
	end
	local results = {}
	for n = 1, limit do
		table.insert(results, '• ' .. mattata.htmlEscape(jdat.streams[n].channel.game) .. ' - <a href="' .. jdat.streams[n].channel.url .. '">' .. mattata.htmlEscape(jdat.streams[n].channel.display_name) .. '</a> <code>[</code>' .. jdat.streams[n].viewers .. ' viewers<code>]</code>')
	end
	mattata.sendMessage(channel_post.chat.id, table.concat(results, '\n'), 'HTML', true, false, channel_post.message_id)
end

function twitch:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, twitch.help, nil, true, false, message.message_id)
		return
	end
	local limit = 4
	if message.chat.type == 'private' then
		limit = 8
	end
	local jstr, res = HTTPS.request('https://api.twitch.tv/kraken/search/streams?q=' .. URL.escape(input) .. '&client_id=' .. configuration.keys.twitch .. '&limit=' .. limit)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat._total == 0 then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	if #jdat.streams < limit then
		limit = #jdat.streams
	end
	local results = {}
	for n = 1, limit do
		table.insert(results, '• ' .. mattata.htmlEscape(jdat.streams[n].channel.game) .. ' - <a href="' .. jdat.streams[n].channel.url .. '">' .. mattata.htmlEscape(jdat.streams[n].channel.display_name) .. '</a> <code>[</code>' .. jdat.streams[n].viewers .. ' viewers<code>]</code>')
	end
	mattata.sendMessage(message.chat.id, table.concat(results, '\n'), 'HTML', true, false, message.message_id)
end

return twitch