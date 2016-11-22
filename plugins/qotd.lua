local qotd = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function qotd:init(configuration)
	qotd.arguments = 'qotd'
	qotd.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('qotd').table
	qotd.help = configuration.commandPrefix .. 'qotd - Sends the quote of the day.'
end

function qotd:onChannelPost(channel_post, configuration)
	local jstr, res = HTTP.request('http://quotes.rest/qod.json')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if string.match(jstr, 'null') then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, '_' .. jdat.contents.quotes[1].quote .. '_ - *' .. jdat.contents.quotes[1].author .. '*', 'Markdown', true, false, channel_post.message_id)
end

function qotd:onMessage(message, language)
	local jstr, res = HTTP.request('http://quotes.rest/qod.json')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if string.match(jstr, 'null') then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '_' .. jdat.contents.quotes[1].quote .. '_ - *' .. jdat.contents.quotes[1].author .. '*', 'Markdown', true, false, message.message_id)
end

return qotd