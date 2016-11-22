local itunes = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function itunes:init(configuration)
	itunes.arguments = 'itunes <song>'
	itunes.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('itunes').table
	itunes.help = configuration.commandPrefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
end

function getOutput(jdat)
	local output = {}
	if jdat.results[1].trackViewUrl and jdat.results[1].trackName then
		table.insert(output, '<b>Name:</b> <a href=\'' .. jdat.results[1].trackViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].trackName) .. '</a>')
	end
	if jdat.results[1].artistViewUrl and jdat.results[1].artistName then
		table.insert(output, '<b>Artist:</b> <a href=\'' .. jdat.results[1].artistViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].artistName) .. '</a>')
	end
	if jdat.results[1].collectionViewUrl and jdat.results[1].collectionName then
		table.insert(output, '<b>Album:</b> <a href=\'' .. jdat.results[1].collectionViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].collectionName) .. '</a>')
	end
	if jdat.results[1].trackNumber and jdat.results[1].trackCount then
		table.insert(output, '<b>Track:</b> ' .. jdat.results[1].trackNumber .. '/' .. jdat.results[1].trackCount)
	end
	if jdat.results[1].discNumber and jdat.results[1].discCount then
		table.insert(output, '<b>Disc:</b> ' .. jdat.results[1].discNumber .. '/' .. jdat.results[1].discCount)
	end
	return table.concat(output, '\n')
end

function itunes:onQueryReceive(callback, message, configuration, language)
	local input = mattata.input(message.reply_to_message.text)
	if callback.data == 'itunesAlbumArtwork' then
		local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input))
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, false)
			return
		end
		local jdat = JSON.decode(jstr)
		if not jdat.results[1] then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.results, nil, false)
			return
		end
		if jdat.results[1].artworkUrl100 then
			local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
			local res = mattata.sendPhoto(message.reply_to_message.from.id, artworkUrl100, nil, false)
			if not res then
				local keyboard = {}
				keyboard.inline_keyboard = {
					{
						{
							text = 'Back',
							callback_data = 'itunesBack'
						}
					}
				}
				mattata.editMessageText(message.chat.id, message.message_id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, JSON.encode(keyboard))
			elseif message.chat.type ~= 'private' then
				local keyboard = {}
				keyboard.inline_keyboard = {
					{
						{
							text = 'Back',
							callback_data = 'itunesBack'
						}
					}
				}
				mattata.editMessageText(message.chat.id, message.message_id, 'I have sent you a private message containing the requested information.', nil, true, JSON.encode(keyboard))
			end
		end
	elseif callback.data == 'itunesBack' then
		local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input))
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, true)
			return
		end
		local jdat = JSON.decode(jstr)
		if not jdat.results[1] then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.results, nil, true)
			return
		end
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Album Artwork',
					callback_data = 'itunesAlbumArtwork'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, getOutput(jdat), 'HTML', true, JSON.encode(keyboard))
	end
end

function itunes:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, itunes.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if not jdat.results[1] then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, getOutput(jdat), 'HTML', true, false, channel_post.message_id)
end

function itunes:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, itunes.help, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'typing')
	local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if not jdat.results[1] then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Album Artwork',
				callback_data = 'itunesAlbumArtwork'
			}
		}
	}
	mattata.sendMessage(message.chat.id, getOutput(jdat), 'HTML', true, false, message.message_id, JSON.encode(keyboard))
end

return itunes