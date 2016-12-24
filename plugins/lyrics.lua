--[[

	This plugin requires you to have Python installed.
	
	Copyright (c) 2016 wrxck
	Licensed under the terms of the MIT license
	See LICENSE for more information
	
]]--

local lyrics = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function lyrics:init(configuration)
	lyrics.arguments =  'lyrics <query>'
	lyrics.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('lyrics').table
	lyrics.inlineCommands = lyrics.commands
	lyrics.help = configuration.commandPrefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics.getLyrics(input, key)
	local jstr, res = https.request('https://api.musixmatch.com/ws/1.1/track.search?apikey=' .. key .. '&q_track=' .. url.escape(input))
	if res ~= 200 then
		return false
	end
	local jdat = json.decode(jstr)
	if jdat.message.header.available == 0 then
		return false
	end
	local title = '<b>' .. mattata.htmlEscape(jdat.message.body.track_list[1].track.track_name) .. '</b> ' .. mattata.htmlEscape(jdat.message.body.track_list[1].track.artist_name) .. '\n🕓 ' .. mattata.formatMilliseconds(math.floor(tonumber(jdat.message.body.track_list[1].track.track_length) * 1000)):gsub('^%d%d:', ''):gsub('^0', '') .. '\n\n'
	local search = mattata.htmlEscape(io.popen('python plugins/lyrics.py "' .. mattata.bashEscape(jdat.message.body.track_list[1].track.artist_name:gsub('"', '\'')) .. '" "' .. mattata.bashEscape(jdat.message.body.track_list[1].track.track_name:gsub('"', '\'')) .. '"'):read('*all'))
	if search:match('^None\n$') then
		return false
	end
	return title .. search, jdat.message.body.track_list[1].track.track_share_url
end

function lyrics.getSpotifyUrl(input)
	local jstr, res = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track')
	if res ~= 200 then
		return false
	end
	local jdat = json.decode(jstr)
	if jdat.tracks.total == 0 then
		return false
	end
	return 'https://open.spotify.com/track/' .. jdat.tracks.items[1].id
end

function lyrics:onInlineQuery(inline_query, configuration, language)
	local input = inline_query.query:gsub('^' .. configuration.commandPrefix .. 'lyrics', ''):gsub(' - ', ' ')
	local jstrSearch, resSearch = https.request('https://api.musixmatch.com/ws/1.1/track.search?apikey=' .. configuration.keys.lyrics .. '&q=' .. url.escape(input))
	if resSearch ~= 200 then
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local musixmatch = json.decode(jstrSearch)
	if musixmatch.message.header.available == 0 then
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.results,
				input_message_content = {
					message_text = language.errors.results
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local lyrics = '*' .. musixmatch.message.body.track_list[1].track.track_name .. ' - ' .. musixmatch.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python plugins/lyrics.py "' .. musixmatch.message.body.track_list[1].track.artist_name .. '" "' .. musixmatch.message.body.track_list[1].track.track_name .. '"'):read('*all'):gsub('^None$', 'I was not able to fetch the lyrics for that song, try clicking one of the buttons below instead.'))
	if io.popen('python plugins/lyrics.py "' .. musixmatch.message.body.track_list[1].track.artist_name .. '" "' .. musixmatch.message.body.track_list[1].track.track_name .. '"'):read('*all') == '' then
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.results,
				input_message_content = {
					message_text = language.errors.results
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jstrSpotify, resSpotify = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track')
	if resSpotify ~= 200 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = musixmatch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = musixmatch.message.body.track_list[1].track.track_name,
				description = musixmatch.message.body.track_list[1].track.artist_name,
				input_message_content = {
					message_text = lyrics,
					parse_mode = 'Markdown'
				},
				reply_markup = keyboard
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdatSpotify = json.decode(jstrSpotify)
	if jdatSpotify.tracks.total == 0 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = musixmatch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = musixmatch.message.body.track_list[1].track.track_name,
				description = musixmatch.message.body.track_list[1].track.artist_name,
				input_message_content = {
					message_text = lyrics,
					parse_mode = 'Markdown'
				},
				reply_markup = keyboard
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'musixmatch',
				url = musixmatch.message.body.track_list[1].track.track_share_url
			},
			{
				text = 'Spotify',
				url = 'https://open.spotify.com/track/' .. jdatSpotify.tracks.items[1].id
			}
		}
	}
	local results = json.encode({
		{
			type = 'article',
			id = '1',
			title = musixmatch.message.body.track_list[1].track.track_name,
			description = musixmatch.message.body.track_list[1].track.artist_name,
			input_message_content = {
				message_text = lyrics,
				parse_mode = 'Markdown'
			},
			reply_markup = keyboard
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
	return
end

function lyrics:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, lyrics.help, nil, true, false, message.message_id)
		return
	end
	input = input:gsub(' - ', ' ')
	mattata.sendChatAction(message.chat.id, 'typing')
	local output, musixmatchUrl = lyrics.getLyrics(input, configuration.keys.lyrics)
	if not output then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	local buttons = {
		{
			text = 'musixmatch',
			url = musixmatchUrl
		}
	}
	local spotifyUrl = lyrics.getSpotifyUrl(input)
	if spotifyUrl then
		table.insert(buttons, {
			text = 'Spotify',
			url = spotifyUrl
		})
	end
	keyboard.inline_keyboard = { buttons }
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return lyrics