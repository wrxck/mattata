local news = {}
local mattata = require('mattata')
local JSON = require('dkjson')

function news:init(configuration)
	news.arguments = 'news <source>'
	news.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('news').table
	news.help = configuration.commandPrefix .. 'news <source> - Returns the latest top headline for the given news source. The current sources are: abc-news-au, ars-technica, associated-press, bbc-news, bbc-sport, bloomberg, business-insider, business-insider-uk, buzzfeed, cnbc, cnn, daily-mail, engadget, entertainment-weekly, espn, espn-cric-info, financial-times, football-italia, fortune, four-four-two, fox-sports, google-news, hacker-news, ign, independent, mashable, metro, mirror, mtv-news, mtv-news-uk, national-geographic, new-scientist, newsweek, new-york-magazine, nfl-news, polygon, recode, reddit-r-all, reuters, sky-news, sky-sports-news, talksport, techcrunch, techradar, the-economist, the-guardian-au, the-guardian-uk, the-hindu, the-huffington-post, the-lad-bible, the-new-york-times, the-next-web, the-sport-bible, the-telegraph, the-times-of-india, the-verge, the-wall-street-journal, the-washington-post, time, usa-today'
end

function news:onMessageReceive(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, news.help, nil, true, false, message.message_id)
		return
	end
	local jstr = io.popen('curl "' .. 'https://newsapi.org/v1/articles?source=' .. input .. '&apiKey=' .. configuration.keys.news .. '"'):read('*all')
	local jdat = JSON.decode(jstr)
	if not jdat.articles then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			text = 'Read more',
			url = jdat.articles[1].url
		}
	}
	mattata.sendMessage(message.chat.id, '*' .. mattata.markdownEscape(jdat.articles[1].title) .. '*\n' .. mattata.markdownEscape(jdat.articles[1].description), 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return news