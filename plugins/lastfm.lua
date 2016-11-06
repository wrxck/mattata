--[[

    Based on lastfm.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local lastfm = {}
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')
local redis = require('mattata-redis')

function lastfm:init(configuration)
	lastfm.arguments = 'lastfm'
	lastfm.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lastfm'):c('np'):c('fmset').table
	lastfm.help = configuration.commandPrefix .. 'np <username> - Returns what you are or were last listening to. If you specify a username, info will be returned for that username.' .. configuration.commandPrefix .. 'fmset <username> - Sets your last.fm username. Use ' .. configuration.commandPrefix .. 'fmset -del to delete your current username.'
end

function setLastfmUsername(user, name)
	local hash = mattata.getUserRedisHash(user, 'lastfm')
	if hash then
		redis:hset(hash, 'lastfm', name)
		return user.first_name .. '\'s last.fm username has been set to \'' .. name .. '\'.'
	end
end

function delLastfmUsername(user)
	local hash = mattata.getUserRedisHash(user, 'lastfm')
	if redis:hexists(hash, 'lastfm') == true then
		redis:hdel(hash, 'lastfm')
		return 'Your last.fm username has been forgotten!'
	else
		return 'You don\'t currently have a last.fm username set!'
	end
end

function getLastfmUsername(user)
	local hash = mattata.getUserRedisHash(user, 'lastfm')
	if hash then
		local name = redis:hget(hash, 'lastfm')
		if not name or name == 'false' then
			return false
		else
			return name
		end
	end
end

function lastfm:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if string.match(message.text, '^' .. configuration.commandPrefix .. 'lastfm') then
		mattata.sendMessage(message.chat.id, lastfm.help, nil, true, false, message.message_id, nil)
		return
	elseif string.match(message.text, '^' .. configuration.commandPrefix .. 'fmset') then
		if not input then
			mattata.sendMessage(message.chat.id, lastfm.help, nil, true, false, message.message_id, nil)
			return
		elseif input == '-del' then
			mattata.sendMessage(message.chat.id, delLastfmUsername(message.from), nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, setLastfmUsername(message.from, input), nil, true, false, message.message_id, nil)
			return
		end
	end
	local url = configuration.apis.lastfm .. configuration.keys.lastfm .. '&user='
	local username
	local alert = ''
	if input then
		username = input
	elseif getLastfmUsername(message.from) then
		username = getLastfmUsername(message.from)
	else
		mattata.sendMessage(message.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, message.message_id, nil)
		return
	end
	url = url .. URL.escape(username)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.error then
		mattata.sendMessage(message.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, message.message_id, nil)
		return
	end
	jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
	if not jdat then
		mattata.sendMessage(message.chat.id, 'No history for this user.' .. alert, nil, true, false, message.message_id, nil)
		return
	end
	local output = input or message.from.first_name
	output = '🎵  ' .. output
	if jdat['@attr'] and jdat['@attr'].nowplaying then
		output = output .. ' is currently listening to:\n'
	else
		output = output .. ' last listened to:\n'
	end
	local title = jdat.name or 'Unknown'
	local artist = 'Unknown'
	if jdat.artist then
		artist = jdat.artist['#text']
	end
	output = output .. artist .. ' - ' .. title .. alert
	local url = configuration.apis.itunes .. URL.escape(artist)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	else
		local jdat = JSON.decode(jstr)
		if tonumber(jdat.resultCount) > 0 then
			if artist and title == 'Unknown' then
				mattata.sendChatAction(message.chat.id, 'typing')
				mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
				return
			else
				if jdat.results[1].artworkUrl100 then
					local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
					mattata.sendChatAction(message.chat.id, 'upload_photo')
					mattata.sendPhoto(message.chat.id, artworkUrl100, output, false, message.message_id, nil)
					return
				else
					mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
					return
				end
			end
		else
			mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
			return
		end
	end
end

return lastfm