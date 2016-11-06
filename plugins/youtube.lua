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
	youtube.help = configuration.commandPrefix .. 'youtube <query> - Sends the first result from YouTube for the given search query. Alias: ' .. configuration.commandPrefix .. 'yt.'
end

function youtube:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, youtube.help, nil, true, false, message.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request('https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&maxResults=1&q=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.pageInfo.totalResults == 0 then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	local output = 'https://www.youtube.com/watch?v=' .. jdat.items[1].id.videoId
	mattata.sendMessage(message.chat.id, output, nil, false, false, message.message_id, nil)
end

return youtube
