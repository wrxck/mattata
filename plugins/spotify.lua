local spotify = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function spotify:init(configuration)
	spotify.command = 'spotify <track ID>'
	spotify.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('spotify', true).table
end
function spotify:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, spotify.documentation)
		return
	else
		input = input:gsub('spotify:track:', '')
	end
	local url = configuration.apis.spotify .. '/tracks/' .. input
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
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
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Album", "url":"' .. album_url .. '"},{"text":"Artist", "url":"' .. artist_url .. '"}]]}')
end
return spotify