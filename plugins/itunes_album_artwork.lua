local itunes_album_artwork = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function itunes_album_artwork:init(configuration)
	itunes_album_artwork.arguments = 'albumart <song/album>'
	itunes_album_artwork.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('albumart', true).table
	itunes_album_artwork.help = configuration.commandPrefix .. 'albumart <song> - Returns a high-quality version of the given song\'s album artwork, from iTunes.'
end

function itunes_album_artwork:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, itunes_album_artwork.help, nil, true, false, msg.message_id, nil)
		return
	else
		local url = configuration.apis.itunes .. URL.escape(input)
		local jstr, res = HTTPS.request(url)
		if res ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		else
			local jdat = JSON.decode(jstr)
			if tonumber(jdat.resultCount) > 0 then
				if jdat.results[1].artworkUrl100 then
					local artworkUrl100 = jdat.results[1].artworkUrl100:gsub('/100x100bb.jpg', '/10000x10000bb.jpg')
					mattata.sendChatAction(msg.chat.id, 'upload_photo')
					mattata.sendPhoto(msg.chat.id, artworkUrl100, nil, false, msg.message_id, nil)
					return
				else
					mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
					return
				end
			else
				mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
				return
			end
		end
	end
end

return itunes_album_artwork