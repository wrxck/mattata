local flickr = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function flickr:init(configuration)
	flickr.arguments = 'flickr <query>'
	flickr.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('flickr').table
	flickr.help = configuration.commandPrefix .. 'flickr <query> - Sends the first result for the given query from Flickr.'
end

function flickr:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, flickr.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' .. configuration.keys.flickr .. '&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_o&text=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.photos.total == '0' then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	mattata.sendPhoto(msg.chat.id, jdat.photos.photo[1].url_o, nil, false, msg.message_id, '{"inline_keyboard":[[{"text":"More results", "url":"https://www.flickr.com/search/?text=' .. URL.escape(input) .. '"}]]}')
end

return flickr