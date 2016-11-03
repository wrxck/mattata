local rss = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function rss:init(configuration)
	rss.arguments = 'rss <feed URL>'
	rss.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('rss').table
	rss.help = configuration.commandPrefix .. 'rss <feed URL> - Sends the latest post from an RSS feed.'
end

function rss.dateEscape(date)
	return date:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/')
end

function rss:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, rss.help, nil, true, false, message.message_id, nil)
		return
	end
	local jstr, res = HTTP.request('http://rss2json.com/api.json?rss_url=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if not string.match(jdat.status, 'ok') then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	local output = '*' .. jdat.feed.title .. '*\n`[' .. rss.dateEscape(jdat.items[1].pubDate) .. ']` [' .. jdat.items[1].title .. '](' .. jdat.items[1].link .. ')'
	if jdat.items[2] then
		output = output .. '\n`[' .. rss.dateEscape(jdat.items[2].pubDate) .. ']` [' .. jdat.items[2].title .. '](' .. jdat.items[2].link .. ')'
	end
	if jdat.items[3] then
		output = output .. '\n`[' .. rss.dateEscape(jdat.items[3].pubDate) .. ']` [' .. jdat.items[3].title .. '](' .. jdat.items[3].link .. ')'
	end
	if jdat.items[4] then
		output = output .. '\n`[' .. rss.dateEscape(jdat.items[4].pubDate) .. ']` [' .. jdat.items[4].title .. '](' .. jdat.items[4].link .. ')'
	end
	if jdat.items[5] then
		output = output .. '\n`[' .. rss.dateEscape(jdat.items[5].pubDate) .. ']` [' .. jdat.items[5].title .. '](' .. jdat.items[5].link .. ')'
	end
	local output_res = mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
	if not output_res then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
end

return rss