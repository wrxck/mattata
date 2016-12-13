local news = {}
local mattata = require('mattata')
local JSON = require('dkjson')

function news:init(configuration)
	news.arguments = 'news <list>'
	news.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('news').table
	news.help = configuration.commandPrefix .. 'news <list> - Returns the latest article from BBC News. If \'list\' is given as an argument, the top headlines from BBC News are sent instead.'
end

function news.listResults(jdat, message, limit)
	local results = {}
	for i = 1, limit do
		table.insert(results, '• <a href="' .. jdat.articles[i].url .. '">' .. mattata.htmlEscape(jdat.articles[i].title) .. '</a>')
	end
	return '<b>Here are the latest stories from BBC News:</b>\n' .. table.concat(results, '\n')
end

function news.getLatestPost(jdat)
	return '<b>' .. mattata.htmlEscape(jdat.articles[1].title) .. '</b>\n' .. mattata.htmlEscape(jdat.articles[1].description) .. '\n<a href="' .. jdat.articles[1].urlToImage .. '">' .. mattata.htmlEscape(jdat.articles[1].author) .. '</a>', jdat.articles[1].url
end

function news:onChannelPost(channel_post, configuration)
	local jstr = '{' .. io.popen('curl -i -H \'x-api-key: ' .. configuration.keys.news .. '\' https://newsapi.org/v1/articles?source=bbc-news&sortBy=top'):read('*all'):match('{(.-)}$') .. '}'
	local jdat = JSON.decode(jstr)
	if not jdat.articles or jdat.status ~= 'ok' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	elseif channel_post.text_lower:match('^' .. configuration.commandPrefix .. 'news list$') then
		mattata.sendMessage(channel_post.chat.id, news.listResults(jdat, channel_post, 4), 'HTML', true, false, channel_post.message_id)
		return
	end
	local output, url = news.getLatestPost(jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read More',
				url = url
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, output, 'HTML', false, false, channel_post.message_id, JSON.encode(keyboard))
end

function news:onMessage(message, configuration)
	local jstr = '{' .. io.popen('curl -i -H \'x-api-key: ' .. configuration.keys.news .. '\' https://newsapi.org/v1/articles?source=bbc-news&sortBy=top'):read('*all'):match('{(.-)}$') .. '}'
	local jdat = JSON.decode(jstr)
	if not jdat.articles or jdat.status ~= 'ok' then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'news list$') then
		local limit = 8
		if message.chat.type ~= 'private' then
			limit = 4
		elseif limit < #jdat.articles then
			limit = #jdat.articles
		end
		mattata.sendMessage(message.chat.id, news.listResults(jdat, message, limit), 'HTML', true, false, message.message_id)
		return
	end
	local output, url = news.getLatestPost(jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read More',
				url = url
			}
		}
	}
	mattata.sendMessage(message.chat.id, output, 'HTML', false, false, message.message_id, JSON.encode(keyboard))
end

return news