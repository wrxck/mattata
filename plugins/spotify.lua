local spotify = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function spotify:init(configuration)
	spotify.arguments = 'spotify <track ID>'
	spotify.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('spotify', true).table
end

function spotify:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, spotify.help, nil, true, false, msg.message_id, nil)
		return
	else
		input = input:gsub('spotify:track:', '')
	end
	local url = configuration.apis.spotify .. '/tracks/' .. input
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name
	local album = jdat.album.name
	local album_url = jdat.album.external_urls.spotify
	local artist = jdat.artists[1].name
	local artist_url = jdat.artists[1].external_urls.spotify
	local track_number = jdat.track_number
	local duration = math.abs(jdat.duration_ms/1000)
	local popularity = jdat.popularity
	local output = ''
	if jdat.explicit == true then
		output = '*\'' .. name .. '\'*, by *' .. artist .. '*, is track number ' .. track_number .. ' on the album *\'' .. album .. '\'*. The song lasts for ' .. duration .. ' seconds. ' .. name .. ' has a Spotify popularity of ' .. popularity .. '. Send `/albumart ' .. album .. '` for a hi-res version of the album artwork. This song is explicit, and is not suitable for children.'
	else
		output = '*\'' .. name .. '\'*, by *' .. artist .. '*, is track number ' .. track_number .. ' on the album *\'' .. album .. '\'*. The song lasts for ' .. duration .. ' seconds. ' .. name .. ' has a Spotify popularity of ' .. popularity .. '. Send `/albumart ' .. album .. '` for a hi-res version of the album artwork.'
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil, '{"inline_keyboard":[[{"text":"Album", "url":"' .. album_url .. '"},{"text":"Artist", "url":"' .. artist_url .. '"}]]}')
end

return spotify