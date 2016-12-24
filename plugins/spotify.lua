local spotify = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function spotify:init(configuration)
	spotify.arguments = 'spotify <query>'
	spotify.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('spotify').table
	spotify.help = configuration.commandPrefix .. 'spotify <query> - Shows information about the top result for the given search query on Spotify.'
end

function spotify.getTrackInfo(jdat)
	if jdat.tracks.total == 0 then return false end
	local output = ''
	if jdat.tracks.items[1].name then
		if jdat.tracks.items[1].external_urls.spotify then
			output = output .. '<b>Song:</b> <a href="' .. jdat.tracks.items[1].external_urls.spotify .. '">' .. mattata.htmlEscape(jdat.tracks.items[1].name) .. '</a>\n'
		else
			output = output .. '<b>Song:</b> ' .. mattata.htmlEscape(jdat.tracks.items[1].name) .. '\n'
		end
	end
	if jdat.tracks.items[1].album.name then
		if jdat.tracks.items[1].album.external_urls.spotify then
			output = output .. '<b>Album:</b> <a href="' .. jdat.tracks.items[1].album.external_urls.spotify .. '">' .. mattata.htmlEscape(jdat.tracks.items[1].album.name) .. '</a>\n'
		else
			output = output .. '<b>Album:</b> ' .. mattata.htmlEscape(jdat.tracks.items[1].album.name) .. '\n'
		end
	end
	if jdat.tracks.items[1].album.artists[1].name then
		if jdat.tracks.items[1].album.artists[1].external_urls.spotify then
			output = output .. '<b>Artist:</b> <a href="' .. jdat.tracks.items[1].album.artists[1].external_urls.spotify .. '">' .. mattata.htmlEscape(jdat.tracks.items[1].album.artists[1].name) .. '</a>\n'
		else
			output = output .. '<b>Artist:</b> ' .. mattata.htmlEscape(jdat.tracks.items[1].album.artists[1].name) .. '\n'
		end
	end
	if jdat.tracks.items[1].disc_number then output = output .. '<b>Disc:</b> ' .. jdat.tracks.items[1].disc_number .. '\n' end
	if jdat.tracks.items[1].track_number then output = output .. '<b>Track:</b> ' .. jdat.tracks.items[1].track_number .. '\n' end
	if jdat.tracks.items[1].popularity then output = output .. '<b>Popularity:</b> ' .. jdat.tracks.items[1].popularity end
	return output
end

function spotify:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, spotify.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track&limit=1')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	local output = spotify.getTrackInfo(jdat)
	if not output then
		mattata.sendMessage(message.chat.id, languages.errors.results, nil, true, false, message.message_id)
	else
		mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
	end
end

return spotify