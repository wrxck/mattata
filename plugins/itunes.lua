local itunes = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function itunes:init(configuration)
	itunes.arguments = 'itunes <song>'
	itunes.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('itunes').table
	itunes.help = configuration.commandPrefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
end

function itunes.getOutput(jdat)
	local output = {}
	if jdat.results[1].trackViewUrl and jdat.results[1].trackName then table.insert(output, '<b>Name:</b> <a href=\'' .. jdat.results[1].trackViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].trackName) .. '</a>') end
	if jdat.results[1].artistViewUrl and jdat.results[1].artistName then table.insert(output, '<b>Artist:</b> <a href=\'' .. jdat.results[1].artistViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].artistName) .. '</a>') end
	if jdat.results[1].collectionViewUrl and jdat.results[1].collectionName then table.insert(output, '<b>Album:</b> <a href=\'' .. jdat.results[1].collectionViewUrl .. '\'>' .. mattata.htmlEscape(jdat.results[1].collectionName) .. '</a>') end
	if jdat.results[1].trackNumber and jdat.results[1].trackCount then table.insert(output, '<b>Track:</b> ' .. jdat.results[1].trackNumber .. '/' .. jdat.results[1].trackCount) end
	if jdat.results[1].discNumber and jdat.results[1].discCount then table.insert(output, '<b>Disc:</b> ' .. jdat.results[1].discNumber .. '/' .. jdat.results[1].discCount) end
	return table.concat(output, '\n')
end

function itunes:onCallbackQuery(callback_query, message, configuration, language)
	local input = mattata.input(message.reply_to_message.text)
	if callback_query.data == 'artwork' then
		local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input))
		if res ~= 200 then mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, false); return end
		local jdat = json.decode(jstr)
		if not jdat.results[1] then mattata.editMessageText(message.chat.id, message.message_id, language.errors.results, nil, false); return end
		if jdat.results[1].artworkUrl100 then
			local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
			mattata.sendPhoto(message.chat.id, artworkUrl100, nil, false)
			mattata.editMessageText(message.chat.id, message.message_id, 'The artwork can be found below:', nil, true)
		end
	end
end

function itunes:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, itunes.help, nil, true, false, message.message_id); return end
	mattata.sendChatAction(message.chat.id, 'typing')
	local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	local jdat = json.decode(jstr)
	if not jdat.results[1] then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id); return end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Get Album Artwork', callback_data = 'itunes:artwork' }}}
	mattata.sendMessage(message.chat.id, itunes.getOutput(jdat), 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return itunes