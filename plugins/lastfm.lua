local lastfm = {}
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function lastfm:init(configuration)
	lastfm.command = 'lastfm'
	lastfm.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lastfm', true):t('np', true):t('fmset', true).table
	lastfm.documentation = configuration.command_prefix .. 'np (username) - Returns what you are or were last listening to. If you specify a username, info will be returned for that username.' .. configuration.command_prefix .. 'fmset <username> - Sets your last.fm username. Otherwise, ' .. configuration.command_prefix .. 'np will use your Telegram username. Use ' .. configuration.command_prefix .. 'fmset -del to delete it.'
end
function lastfm:action(msg, configuration)
	local input = functions.input(msg.text)
	local from_id_str = tostring(msg.from.id)
	self.database.userdata[from_id_str] = self.database.userdata[from_id_str] or {}
	if string.match(msg.text, '^' .. configuration.command_prefix .. 'lastfm') then
		functions.send_reply(msg, lastfm.documentation)
		return
	elseif string.match(msg.text, '^' .. configuration.command_prefix .. 'fmset') then
		if not input then
			functions.send_reply(msg, lastfm.documentation)
		elseif input == '-del' then
			self.database.userdata[from_id_str].lastfm = nil
			functions.send_reply(msg, 'Your last.fm username has been forgotten.')
		else
			self.database.userdata[from_id_str].lastfm = input
			functions.send_reply(msg, 'Your last.fm username has been set to "' .. input .. '".')
		end
		return
	end
	local url = configuration.apis.lastfm .. configuration.keys.lastfm .. '&user='
	local username
	local alert = ''
	if input then
		username = input
	elseif self.database.userdata[from_id_str].lastfm then
		username = self.database.userdata[from_id_str].lastfm
	elseif msg.from.username then
		username = msg.from.username
		alert = '\n\nYour username has been set to ' .. username .. '.\nTo change it, use ' .. configuration.command_prefix .. 'fmset <username>.'
		self.database.userdata[from_id_str].lastfm = username
	else
		functions.send_reply(msg, 'Please specify your last.fm username or set it with ' .. configuration.command_prefix .. 'fmset.')
		return
	end
	url = url .. URL.escape(username)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.error then
		functions.send_reply(msg, 'Please specify your last.fm username or set it with ' .. configuration.command_prefix .. 'fmset.')
		return
	end
	jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
	if not jdat then
		functions.send_reply(msg, 'No history for this user.' .. alert)
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
		functions.send_reply(msg, configuration.errors.connection)
		return
	else
		local jdat = JSON.decode(jstr)
		if tonumber(jdat.resultCount) > 0 then
			if jdat.results[1].artworkUrl100 then
				local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
				telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
				functions.send_photo(msg.chat.id, functions.download_to_file(artworkUrl100), output, msg.message_id)
				return
			else
				functions.send_reply(msg, output)
				return
			end
		else
			functions.send_reply(msg, output)
			return
		end
	end
end
return lastfm