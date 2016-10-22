local lastfm = {}
local HTTP = require('dependencies.socket.http')
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function lastfm:init(configuration)
	lastfm.arguments = 'lastfm'
	lastfm.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lastfm', true):c('np', true):c('fmset', true).table
	lastfm.help = configuration.commandPrefix .. 'np (username) - Returns what you are or were last listening to. If you specify a username, info will be returned for that username.' .. configuration.commandPrefix .. 'fmset <username> - Sets your last.fm username. Otherwise, ' .. configuration.commandPrefix .. 'np will use your Telegram username. Use ' .. configuration.commandPrefix .. 'fmset -del to delete it.'
end

function lastfm:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	local from_id_str = tostring(msg.from.id)
	self.db.userdata[from_id_str] = self.db.userdata[from_id_str] or {}
	if string.match(msg.text, '^' .. configuration.commandPrefix .. 'lastfm') then
		mattata.sendMessage(msg.chat.id, lastfm.help, nil, true, false, msg.message_id, nil)
		return
	elseif string.match(msg.text, '^' .. configuration.commandPrefix .. 'fmset') then
		if not input then
			mattata.sendMessage(msg.chat.id, lastfm.help, nil, true, false, msg.message_id, nil)
		elseif input == '-del' then
			self.db.userdata[from_id_str].lastfm = nil
			mattata.sendMessage(msg.chat.id, 'Your last.fm username has been forgotten.', nil, true, false, msg.message_id, nil)
		else
			self.db.userdata[from_id_str].lastfm = input
			mattata.sendMessage(msg.chat.id, 'Your last.fm username has been set to "' .. input .. '".', nil, true, false, msg.message_id, nil)
		end
		return
	end
	local url = configuration.apis.lastfm .. configuration.keys.lastfm .. '&user='
	local username
	local alert = ''
	if input then
		username = input
	elseif self.db.userdata[from_id_str].lastfm then
		username = self.db.userdata[from_id_str].lastfm
	elseif msg.from.username then
		username = msg.from.username
		alert = '\n\nYour username has been set to ' .. username .. '.\nTo change it, use ' .. configuration.commandPrefix .. 'fmset <username>.'
		self.db.userdata[from_id_str].lastfm = username
	else
		mattata.sendMessage(msg.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, msg.message_id, nil)
		return
	end
	url = url .. URL.escape(username)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.error then
		mattata.sendMessage(msg.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, msg.message_id, nil)
		return
	end
	jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
	if not jdat then
		mattata.sendMessage(msg.chat.id, 'No history for this user.' .. alert, nil, true, false, msg.message_id, nil)
		return
	end
	local output = input or msg.from.first_name
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
	output = output .. title .. ' - ' .. artist .. alert
	local url = configuration.apis.itunes .. URL.escape(artist)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	else
		local jdat = JSON.decode(jstr)
		if tonumber(jdat.resultCount) > 0 then
			if artist and title == 'Unknown' then
				mattata.sendChatAction(msg.chat.id, 'typing')
				mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
				return
			else
				if jdat.results[1].artworkUrl100 then
					local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
					mattata.sendChatAction(msg.chat.id, 'upload_photo')
					mattata.sendPhoto(msg.chat.id, artworkUrl100, output, false, msg.message_id, nil)
					return
				else
					mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
					return
				end
			end
		else
			mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
			return
		end
	end
end

return lastfm