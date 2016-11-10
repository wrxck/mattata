local news = {}
local mattata = require('mattata')
local JSON = require('dkjson')

function news:init(configuration)
	news.arguments = 'news <source>'
	news.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('news').table
	news.help = configuration.commandPrefix .. 'news <source> - Returns the latest top headline for the given news source. The current sources are: abc-news-au, ars-technica, associated-press, bbc-news, bbc-sport, bloomberg, business-insider, business-insider-uk, buzzfeed, cnbc, cnn, daily-mail, engadget, entertainment-weekly, espn, espn-cric-info, financial-times, football-italia, fortune, four-four-two, fox-sports, google-news, hacker-news, ign, independent, mashable, metro, mirror, mtv-news, mtv-news-uk, national-geographic, new-scientist, newsweek, new-york-magazine, nfl-news, polygon, recode, reddit-r-all, reuters, sky-news, sky-sports-news, talksport, techcrunch, techradar, the-economist, the-guardian-au, the-guardian-uk, the-hindu, the-huffington-post, the-lad-bible, the-new-york-times, the-next-web, the-sport-bible, the-telegraph, the-times-of-india, the-verge, the-wall-street-journal, the-washington-post, time, usa-today'
end

function news:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, news.help, nil, true, false, message.message_id)
		return
	end
	local url = 'https://newsapi.org/v1/articles?source=' .. input .. '&apiKey=' .. configuration.keys.news
	local jstr = io.popen('curl "' .. url .. '"'):read('*all')
	local jdat = JSON.decode(jstr)
	if not jdat.articles then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local output = '*' .. mattata.markdownEscape(jdat.articles[1].title) .. '*\n' .. mattata.markdownEscape(jdat.articles[1].description)
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat.articles[1].url .. '"}]]}')
end

return news