--[[

    Based on lastfm.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local lastfm = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local redis = require('mattata-redis')

function lastfm:init(configuration)
	lastfm.arguments = 'lastfm'
	lastfm.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lastfm'):c('np'):c('fmset').table
	lastfm.inlineCommands = lastfm.commands
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

function lastfm:onInlineQuery(inline_query, configuration, language)
	local input = inline_query.query:gsub('^' .. configuration.commandPrefix .. 'np ', '')
	local url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user='
	local username, results, output
	if inline_query.query == configuration.commandPrefix .. 'np' then
		if not getLastfmUsername(inline_query.from) then
			local results = JSON.encode({
				{
					type = 'article',
					id = '1',
					title = 'An error occured!',
					description = 'Please send ' .. configuration.commandPrefix .. 'fmset <username> to me via private chat!',
					input_message_content = {
						message_text = 'An error occured!\nPlease send ' .. configuration.commandPrefix .. 'fmset <username> to me via private chat!'
					}
				}
			})
			mattata.answerInlineQuery(inline_query.id, results, 0)
			return
		end
		username = getLastfmUsername(inline_query.from)
	else
		username = input
	end
	url = url .. URL.escape(username)
	local jstr, res = HTTP.request(url)
	local jdat = JSON.decode(jstr)
	jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
	if inline_query.query == configuration.commandPrefix .. 'np' then
		output =  inline_query.from.first_name .. ' (last.fm/user/' .. username .. ')'
	else
		output = username
	end
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
	output = output .. artist .. ' - ' .. title
	if jdat.image[4]['#text'] == '' then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = artist .. ' - ' .. title,
				description = 'Click to send the result.',
				input_message_content = {
					message_text = output
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local results = JSON.encode({
		{
			type = 'photo',
			id = '1',
			photo_url = jdat.image[4]['#text'],
			thumb_url = jdat.image[4]['#text'],
			caption = output
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function lastfm:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'lastfm$') then
		mattata.sendMessage(message.chat.id, lastfm.help, nil, true, false, message.message_id)
		return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'fmset') then
		if not input then
			mattata.sendMessage(message.chat.id, lastfm.help, nil, true, false, message.message_id)
			return
		elseif input == '-del' then
			mattata.sendMessage(message.chat.id, delLastfmUsername(message.from), nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, setLastfmUsername(message.from, input), nil, true, false, message.message_id)
		return
	end
	local username, output
	if input then
		username = input
	elseif getLastfmUsername(message.from) then
		username = getLastfmUsername(message.from)
	else
		mattata.sendMessage(message.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user=' .. URL.escape(username))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.error then
		mattata.sendMessage(message.chat.id, 'Please specify your last.fm username or set it with ' .. configuration.commandPrefix .. 'fmset.', nil, true, false, message.message_id)
		return
	end
	jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
	if not jdat then
		mattata.sendMessage(message.chat.id, 'No history for this user.', nil, true, false, message.message_id)
		return
	end
	if not input then
		output = message.from.first_name .. '(last.fm/user/' .. username .. ')'
	else
		output = input
	end
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
	if artist and title == 'Unknown' then
		mattata.sendChatAction(message.chat.id, 'typing')
		mattata.sendMessage(message.chat.id, output .. artist .. ' - ' .. title, nil, true, false, message.message_id)
		return
	end
	if jdat.image[1]['#text'] == '' then
		mattata.sendMessage(message.chat.id, output .. artist .. ' - ' .. title, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendPhoto(message.chat.id, jdat.image[4]['#text'], output .. artist .. ' - ' .. title, false, message.message_id)
end

return lastfm