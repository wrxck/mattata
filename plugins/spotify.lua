local spotify = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function spotify:init(configuration)
	spotify.arguments = 'spotify <track ID>'
	spotify.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('spotify').table
	spotify.help = configuration.commandPrefix .. 'spotify <track ID> - Sends information about the given Spotify track ID.'
end

function spotify:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, spotify.help, nil, true, false, channel_post.message_id)
		return
	end
	input = input:gsub('spotify:track:', '')
	local jstr, res = HTTPS.request('https://api.spotify.com/v1/tracks/' .. input)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*\'' .. jdat.name .. '\'*, by *' .. jdat.artists[1].name .. '*, is track number ' .. jdat.track_number .. ' on the album *\'' .. jdat.album.name .. '\'*. The song lasts for ' .. math.abs(jdat.duration_ms/1000) .. ' seconds. ' .. jdat.name .. ' has a Spotify popularity of ' .. jdat.popularity .. '.'
	if jdat.explicit == true then
		output = output .. ' This song is explicit, and is not suitable for children.'
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Album',
				url = jdat.album.external_urls.spotify
			},
			{
				text = 'Artist',
				url = jdat.artists[1].external_urls.spotify
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function spotify:onMessageReceive(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, spotify.help, nil, true, false, message.message_id)
		return
	end
	input = input:gsub('spotify:track:', '')
	local jstr, res = HTTPS.request('https://api.spotify.com/v1/tracks/' .. input)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*\'' .. jdat.name .. '\'*, by *' .. jdat.artists[1].name .. '*, is track number ' .. jdat.track_number .. ' on the album *\'' .. jdat.album.name .. '\'*. The song lasts for ' .. math.abs(jdat.duration_ms/1000) .. ' seconds. ' .. jdat.name .. ' has a Spotify popularity of ' .. jdat.popularity .. '.'
	if jdat.explicit == true then
		output = output .. ' This song is explicit, and is not suitable for children.'
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Album',
				url = jdat.album.external_urls.spotify
			},
			{
				text = 'Artist',
				url = jdat.artists[1].external_urls.spotify
			}
		}
	}
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return spotify