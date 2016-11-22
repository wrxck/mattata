--[[

	This plugin requires you to have Python 3 installed.
	
	Copyright (c) 2016 wrxck
	Licensed under the terms of the MIT license
	See LICENSE for more information
	
]]--

local lyrics = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function lyrics:init(configuration)
	lyrics.arguments =  'lyrics <query>'
	lyrics.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lyrics').table
	lyrics.inlineCommands = lyrics.commands
	lyrics.help = configuration.commandPrefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics:onInlineQuery(inline_query, configuration, language)
	local input = inline_query.query:gsub('^' .. configuration.commandPrefix .. 'lyrics', ''):gsub(' - ', ' ')
	local jstrSearch, resSearch = HTTPS.request('https://api.musixmatch.com/ws/1.1/' .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. input:gsub(' ', '%%20'))
	if resSearch ~= 200 then
		local results = JSON.encode({
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
	local jdatSearch = JSON.decode(jstrSearch)
	if jdatSearch.message.header.available == 0 then
		local results = JSON.encode({
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
	local lyrics = '*' .. jdatSearch.message.body.track_list[1].track.track_name .. ' - ' .. jdatSearch.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name .. '"'):read('*all'):gsub('^None$', 'I was not able to fetch the lyrics for that song, try clicking one of the buttons below instead.'))
	if io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name .. '"'):read('*all') == '' then
		local results = JSON.encode({
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
	local jstrSpotify, resSpotify = HTTPS.request('https://api.spotify.com/v1/search?q=' .. URL.escape(input) .. '&type=track')
	if resSpotify ~= 200 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = jdatSearch.message.body.track_list[1].track.track_name,
				description = jdatSearch.message.body.track_list[1].track.artist_name,
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
	local jdatSpotify = JSON.decode(jstrSpotify)
	if jdatSpotify.tracks.total == 0 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = jdatSearch.message.body.track_list[1].track.track_name,
				description = jdatSearch.message.body.track_list[1].track.artist_name,
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
				url = jdatSearch.message.body.track_list[1].track.track_share_url
			},
			{
				text = 'Spotify',
				url = 'https://open.spotify.com/track/' .. jdatSpotify.tracks.items[1].id
			}
		}
	}
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = jdatSearch.message.body.track_list[1].track.track_name,
			description = jdatSearch.message.body.track_list[1].track.artist_name,
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

function lyrics:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, lyrics.help, nil, true, false, channel_post.message_id)
		return
	end
	input = input:gsub(' - ', ' ')
	local jstrSearch, resSearch = HTTPS.request('https://api.musixmatch.com/ws/1.1/' .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. URL.escape(input))
	if resSearch ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdatSearch = JSON.decode(jstrSearch)
	if jdatSearch.message.header.available == 0 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local lyrics = '*' .. jdatSearch.message.body.track_list[1].track.track_name .. ' - ' .. jdatSearch.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name:gsub('"', '\'') .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name:gsub('"', '\'') .. '"'):read('*all'):gsub('^None$', 'I was not able to fetch the lyrics for that song, try clicking one of the buttons below instead.'))
	if io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name:gsub('"', '\'') .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name:gsub('"', '\'') .. '"'):read('*all') == 'None' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jstrSpotify, resSpotify = HTTPS.request('https://api.spotify.com/v1/search?q=' .. URL.escape(input) .. '&type=track')
	if resSpotify ~= 200 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		mattata.sendMessage(channel_post.chat.id, lyrics, 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
		return
	end
	local jdatSpotify = JSON.decode(jstrSpotify)
	if jdatSpotify.tracks.total == 0 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		mattata.sendMessage(channel_post.chat.id, lyrics, 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'musixmatch',
				url = jdatSearch.message.body.track_list[1].track.track_share_url
			},
			{
				text = 'Spotify',
				url = 'https://open.spotify.com/track/' .. jdatSpotify.tracks.items[1].id
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, lyrics, 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function lyrics:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, lyrics.help, nil, true, false, message.message_id)
		return
	end
	input = input:gsub(' - ', ' ')
	mattata.sendChatAction(message.chat.id, 'typing')
	local jstrSearch, resSearch = HTTPS.request('https://api.musixmatch.com/ws/1.1/' .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. URL.escape(input))
	if resSearch ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdatSearch = JSON.decode(jstrSearch)
	if jdatSearch.message.header.available == 0 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local lyrics = '*' .. jdatSearch.message.body.track_list[1].track.track_name .. ' - ' .. jdatSearch.message.body.track_list[1].track.artist_name .. '*\n\n' .. mattata.markdownEscape(io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name:gsub('"', '\'') .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name:gsub('"', '\'') .. '"'):read('*all'):gsub('^None$', 'I was not able to fetch the lyrics for that song, try clicking one of the buttons below instead.'))
	if io.popen('python plugins/lyrics.py "' .. jdatSearch.message.body.track_list[1].track.artist_name:gsub('"', '\'') .. '" "' .. jdatSearch.message.body.track_list[1].track.track_name:gsub('"', '\'') .. '"'):read('*all') == 'None' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jstrSpotify, resSpotify = HTTPS.request('https://api.spotify.com/v1/search?q=' .. URL.escape(input) .. '&type=track')
	if resSpotify ~= 200 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
		return
	end
	local jdatSpotify = JSON.decode(jstrSpotify)
	if jdatSpotify.tracks.total == 0 then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'musixmatch',
					url = jdatSearch.message.body.track_list[1].track.track_share_url
				}
			}
		}
		mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'musixmatch',
				url = jdatSearch.message.body.track_list[1].track.track_share_url
			},
			{
				text = 'Spotify',
				url = 'https://open.spotify.com/track/' .. jdatSpotify.tracks.items[1].id
			}
		}
	}
	mattata.sendMessage(message.chat.id, lyrics, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return lyrics