local itunes = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function itunes:init(configuration)
	itunes.arguments = 'itunes <song>'
	itunes.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('itunes').table
	itunes.help = configuration.commandPrefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
end

function itunes:onQueryReceive(callback, message, configuration)
	if callback.data == 'itunes_send_artwork' then
		local input = message.reply_to_message.text:gsub(configuration.commandPrefix .. 'itunes ', '')
		local url = configuration.apis.itunes .. URL.escape(input)
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, configuration.errors.connection, nil, false, '{"inline_keyboard":[[{"text":"Try Again", "callback_data":"itunes_send_artwork"}]]}')
			return
		end
		local jdat = JSON.decode(jstr)
		if jdat.results[1] then
			if jdat.results[1].artworkUrl100 then
				local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
				local res = mattata.sendPhoto(message.reply_to_message.from.id, artworkUrl100, nil, false, nil, nil)
				if not res then
					mattata.editMessageText(message.chat.id, message.message_id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"itunes_back"}]]}')
				elseif message.chat.type ~= 'private' then
					mattata.editMessageText(message.chat.id, message.message_id, 'I have sent you a private message containing the requested information.', nil, true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"itunes_back"}]]}')
				end
			end
		end
	end
	if callback.data == 'itunes_back' then
		local url = configuration.apis.itunes .. URL.escape(message.text)
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, configuration.errors.connection, nil, true, '{"inline_keyboard":[[{"text":"Try Again", "callback_data":"itunes_back"}]]}')
			return
		end
		local track, artist, collection, trackNumber, discNumber = ''
		local jdat = JSON.decode(jstr)
		if jdat.results[1] then
			if jdat.results[1].trackName and jdat.results[1].trackViewUrl then
				trackOutput = '*Track Name:* [' .. jdat.results[1].trackName .. '](' .. jdat.results[1].trackViewUrl .. ')'
			end
			if jdat.results[1].artistName and jdat.results[1].artistViewUrl then
				artistOutput = '\n*Artist:* [' .. jdat.results[1].artistName .. '](' .. jdat.results[1].artistViewUrl .. ')'
			end
			if jdat.results[1].collectionName and jdat.results[1].collectionViewUrl then
				collectionOutput = '\n*Album:* [' .. jdat.results[1].collectionName .. '](' .. jdat.results[1].collectionViewUrl .. ')'
			end
			if jdat.results[1].trackNumber and jdat.results[1].trackCount then
				trackNumberOutput = '\n*Track Number:* ' .. jdat.results[1].trackNumber .. '/' .. jdat.results[1].trackCount
			end
			if jdat.results[1].discNumber and jdat.results[1].discCount then
				discNumberOutput = '\n*Disc Number:* ' .. jdat.results[1].discNumber .. '/' .. jdat.results[1].discCount
			end
		end
		local output = trackOutput .. artistOutput .. collectionOutput .. trackNumberOutput .. discNumberOutput
		mattata.editMessageText(message.chat.id, message.message_id, output, 'Markdown', true, '{"inline_keyboard":[[{"text":"Get Album Artwork", "callback_data":"itunes_send_artwork"}]]}')
	end
end

function itunes:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, itunes.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.itunes .. URL.escape(input)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, '{"inline_keyboard":[[{"text":"Try Again", "callback_data":"itunes_back"}]]}')
		return
	end
	mattata.sendChatAction(message.chat.id, 'typing')
	local track, artist, collection, trackNumber, discNumber = ''
	local jdat = JSON.decode(jstr)
	if jdat.results[1] then
		if jdat.results[1].trackName and jdat.results[1].trackViewUrl then
			trackOutput = '*Track Name:* [' .. jdat.results[1].trackName .. '](' .. jdat.results[1].trackViewUrl .. ')'
		end
		if jdat.results[1].artistName and jdat.results[1].artistViewUrl then
			artistOutput = '\n*Artist:* [' .. jdat.results[1].artistName .. '](' .. jdat.results[1].artistViewUrl .. ')'
		end
		if jdat.results[1].collectionName and jdat.results[1].collectionViewUrl then
			collectionOutput = '\n*Album:* [' .. jdat.results[1].collectionName .. '](' .. jdat.results[1].collectionViewUrl .. ')'
		end
		if jdat.results[1].trackNumber and jdat.results[1].trackCount then
			trackNumberOutput = '\n*Track Number:* ' .. jdat.results[1].trackNumber .. '/' .. jdat.results[1].trackCount
		end
		if jdat.results[1].discNumber and jdat.results[1].discCount then
			discNumberOutput = '\n*Disc Number:* ' .. jdat.results[1].discNumber .. '/' .. jdat.results[1].discCount
		end
	end
	local output = trackOutput .. artistOutput .. collectionOutput .. trackNumberOutput .. discNumberOutput
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"Get Album Artwork", "callback_data":"itunes_send_artwork"}]]}')
end

return itunes