local synonym = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function synonym:init(configuration)
	synonym.arguments = 'synonym <word>'
	synonym.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('synonym').table
	synonym.help = configuration.commandPrefix .. 'synonym <word> - Sends a synonym of the given word.'
end

function synonym:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, synonym.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=' .. configuration.keys.synonym .. '&lang=' .. configuration.language .. '-' .. configuration.language .. '&text=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jstr == '{"head":{},"def":[]}' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, 'You could use the word *' .. jdat.def[1].tr[1].text .. '* instead.', 'Markdown', true, false, channel_post.message_id)
end

function synonym:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, synonym.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=' .. configuration.keys.synonym .. '&lang=' .. configuration.language .. '-' .. configuration.language .. '&text=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jstr == '{"head":{},"def":[]}' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, 'You could use the word *' .. jdat.def[1].tr[1].text .. '* instead.', 'Markdown', true, false, message.message_id)
end

return synonym