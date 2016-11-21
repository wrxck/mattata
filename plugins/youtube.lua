--[[

    Based on youtube.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local youtube = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function youtube:init(configuration)
	youtube.arguments = 'youtube <query>'
	youtube.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('youtube'):c('yt').table
	youtube.help = configuration.commandPrefix .. 'youtube <query> - Sends the top results from YouTube for the given search query. Alias: ' .. configuration.commandPrefix .. 'yt.'
end

function youtube:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, youtube.help, nil, true, false, channel_post.message_id)
		return
	end
	local url
	if message.chat.type == 'private' then
		url = 'https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&maxResults=8&q=' .. URL.escape(input)
	else
		url = 'https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&maxResults=4&q=' .. URL.escape(input)
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.pageInfo.totalResults == 0 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local results = {}
	for n in pairs(jdat.items) do
		table.insert(results, '• [' .. mattata.markdownEscape(jdat.items[n].snippet.title) .. '](https://www.youtube.com/watch?v=' .. jdat.items[n].id.videoId .. ')')
	end
	local output = table.concat(results, '\n')
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id)
end

function youtube:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, youtube.help, nil, true, false, message.message_id)
		return
	end
	local url
	if message.chat.type == 'private' then
		url = 'https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&maxResults=8&q=' .. URL.escape(input)
	else
		url = 'https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&maxResults=4&q=' .. URL.escape(input)
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.pageInfo.totalResults == 0 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local results = {}
	for n in pairs(jdat.items) do
		table.insert(results, '• [' .. mattata.markdownEscape(jdat.items[n].snippet.title) .. '](https://www.youtube.com/watch?v=' .. jdat.items[n].id.videoId .. ')')
	end
	local output = table.concat(results, '\n')
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return youtube
