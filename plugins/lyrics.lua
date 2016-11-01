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
local JSON = require('dkjson')

function lyrics:init(configuration)
	lyrics.arguments =  'lyrics <query>'
	lyrics.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lyrics').table
	lyrics.help = configuration.commandPrefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, lyrics.help, nil, true, false, msg.message_id, nil)
		return
	else
		input = input:gsub(' - ', ' ')
	end
	mattata.sendChatAction(msg.chat.id, 'typing')
	local url_id = configuration.apis.lyrics .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. input:gsub(' ', '%%20')
	local jstr_id, res_id = HTTPS.request(url_id)
	if res_id ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat_id = JSON.decode(jstr_id)
	if jdat_id.message.header.available == 0 or nil then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.lyrics .. 'track.lyrics.get?apikey=' .. configuration.keys.lyrics .. '&track_id=' .. jdat_id.message.body.track_list[1].track.track_id
	local jstr, res_lyrics = HTTPS.request(url)
	if res_lyrics ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.message.body.lyrics == nil then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local spotify_url, soundcloud_url
	local lyrics = '*' .. jdat_id.message.body.track_list[1].track.track_name .. ' - ' .. jdat_id.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python3 plugins/lyrics.py ' .. jdat_id.message.body.track_list[1].track.track_share_url):read('*all'))
	if io.popen('python3 plugins/lyrics.py ' .. jdat_id.message.body.track_list[1].track.track_share_url):read('*all') == '' then
		lyrics = configuration.errors.results
	end
	if jdat_id.message.body.track_list[1].track.track_soundcloud_id ~= 0 then
		if jdat_id.message.body.track_list[1].track.track_spotify_id ~= '' or nil then
			local soundcloud_jstr, soundcloud_res = HTTPS.request('https://api.soundcloud.com/tracks/' .. jdat_id.message.body.track_list[1].track.track_soundcloud_id .. '.json?client_id=386b66fb8e6e68704b52ab59edcdccc6')
			if soundcloud_res ~= 200 then
				spotify_url = 'https://open.spotify.com/track/' .. jdat_id.message.body.track_list[1].track.track_spotify_id
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"},{"text":"Spotify", "url":"' .. spotify_url .. '"}]]}')
				return
			end
			local soundcloud_jdat = JSON.decode(soundcloud_jstr)
			if soundcloud_jdat.permalink_url then
				soundcloud_url = soundcloud_jdat.permalink_url
				spotify_url = 'https://open.spotify.com/track/' .. jdat_id.message.body.track_list[1].track.track_spotify_id
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"},{"text":"SoundCloud", "url":"' .. soundcloud_url .. '"},{"text":"Spotify", "url":"' .. spotify_url .. '"}]]}')
				return
			else
				spotify_url = 'https://open.spotify.com/track/' .. jdat_id.message.body.track_list[1].track.track_spotify_id
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"},{"text":"Spotify", "url":"' .. spotify_url .. '"}]]}')
				return
			end
		else
			local soundcloud_jstr, soundcloud_res = HTTPS.request('https://api.soundcloud.com/tracks/' .. jdat_id.message.body.track_list[1].track.track_soundcloud_id .. '.json?client_id=386b66fb8e6e68704b52ab59edcdccc6')
			if soundcloud_res ~= 200 then
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"}]]}')
				return
			end
			local soundcloud_jdat = JSON.decode(soundcloud_jstr)
			local soundcloud_url = ''
			if soundcloud_jdat.permalink_url then
				soundcloud_url = soundcloud_jdat.permalink_url
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"},{"text":"SoundCloud", "url":"' .. soundcloud_url .. '"}]]}')
				return
			else
				mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"}]]}')
				return
			end
		end
	elseif jdat_id.message.body.track_list[1].track.track_spotify_id ~= '' then
		spotify_url = 'https://open.spotify.com/track/' .. jdat_id.message.body.track_list[1].track.track_spotify_id
		mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"},{"text":"Spotify", "url":"' .. spotify_url .. '"}]]}')
		return
	else
		mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"musixmatch", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"}]]}')
		return
	end
end

return lyrics