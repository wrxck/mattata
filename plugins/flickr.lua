local flickr = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function flickr:init(configuration)
	flickr.arguments = 'flickr <query>'
	flickr.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('flickr').table
	flickr.inlineCommands = flickr.commands
	flickr.help = configuration.commandPrefix .. 'flickr <query> - Sends the first result for the given query from Flickr.'
end

function flickr:onInlineQuery(inline_query, configuration)
	local input = mattata.input(inline_query.query)
	local jstr = HTTPS.request('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' .. configuration.keys.flickr .. '&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_s,url_q,url_m,url_n,url_z,url_c,url_l,url_o&text=' .. URL.escape(input))
	local jdat = JSON.decode(jstr)
	local resultsList = {}
	local resultId = 1
	for n in pairs(jdat.photos.photo) do
		if jdat.photos.photo[n].url_l and jdat.photos.photo[n].url_s then
			if string.match(jdat.photos.photo[n].url_l, '%.jpe?g$') then
				local result = {
					type = 'photo',
					id = tostring(resultId),
					photo_url = jdat.photos.photo[n].url_l,
					thumb_url = jdat.photos.photo[n].url_s,
					photo_width = tonumber(jdat.photos.photo[n].width_l),
					photo_height = tonumber(jdat.photos.photo[n].height_l),
					caption = 'You searched for: ' .. input
				}
				table.insert(resultsList, result)
			end
		end
		resultId = resultId + 1
	end
	mattata.answerInlineQuery(inline_query.id, JSON.encode(resultsList), 0)
end

function flickr:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, flickr.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' .. configuration.keys.flickr .. '&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_o&text=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.photos.total == '0' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'More results',
				url = 'https://www.flickr.com/search/?text=' .. URL.escape(input)
			}
		}
	}
	mattata.sendPhoto(channel_post.chat.id, jdat.photos.photo[1].url_o, nil, false, channel_post.message_id, JSON.encode(keyboard))
end

function flickr:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, flickr.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=' .. configuration.keys.flickr .. '&format=json&nojsoncallback=1&privacy_filter=1&safe_search=3&media=photos&sort=relevance&is_common=true&per_page=20&extras=url_o&text=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.photos.total == '0' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'More results',
				url = 'https://www.flickr.com/search/?text=' .. URL.escape(input)
			}
		}
	}
	mattata.sendPhoto(message.chat.id, jdat.photos.photo[1].url_o, nil, false, message.message_id, JSON.encode(keyboard))
end

return flickr