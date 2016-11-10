--[[

	This plugin requires you to have Python 3 installed and the the following Python dependencies:
		- BeautifulSoup
		- demjson
	
	These dependencies can be installed automatically by using the install-dependencies.sh script.
	
	Copyright (c) 2016 wrxck
	Licensed under the terms of the MIT license
	See LICENSE for more information
	
	Credit to @imandaneshi for the Python script
	
]]--

local lyrics = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function lyrics:init(configuration)
	lyrics.arguments =  'lyrics <query>'
	lyrics.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lyrics').table
	lyrics.help = configuration.commandPrefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, lyrics.help, nil, true, false, message.message_id, nil)
		return
	else
		input = input:gsub(' - ', ' ')
	end
	mattata.sendChatAction(message.chat.id, 'typing')
	local jstrSearch, resSearch = HTTPS.request(configuration.apis.lyrics .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. input:gsub(' ', '%%20'))
	if resSearch ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdatSearch = JSON.decode(jstrSearch)
	if jdatSearch.message.header.available == 0 then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local lyrics = '*' .. jdatSearch.message.body.track_list[1].track.track_name .. ' - ' .. jdatSearch.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python3 plugins/lyrics.py ' .. jdatSearch.message.body.track_list[1].track.track_share_url):read('*all'))
	if io.popen('python3 plugins/lyrics.py ' .. jdatSearch.message.body.track_list[1].track.track_share_url):read('*all') == '' then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local jstrSpotify, resSpotify = HTTPS.request('https://api.spotify.com/v1/search?q=' .. URL.escape(input) .. '&type=track')
	if resSpotify ~= 200 then
		mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdatSearch.message.body.track_list[1].track.track_share_url .. '"}]]}')
		return
	end
	local jdatSpotify = JSON.decode(jstrSpotify)
	if jdatSpotify.tracks.total == 0 then
		mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdatSearch.message.body.track_list[1].track.track_share_url .. '"}]]}')
		return
	end
	mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdatSearch.message.body.track_list[1].track.track_share_url .. '"},{"text":"Spotify", "url":"https://open.spotify.com/track/' .. jdatSpotify.tracks.items[1].id .. '"}]]}')
end

return lyrics