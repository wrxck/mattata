local rss = {}
local functions = require('functions')
local HTTP = require('dependencies.socket.http')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
function rss:init(configuration)
	rss.command = 'rss <feed URL>'
	rss.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('rss', true).table
	rss.documentation = configuration.command_prefix .. 'rss <feed URL> - Sends the latest post from an RSS feed.'
end
function rss:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, rss.documentation)
		return
	end
	local jstr, res = HTTP.request('http://rss2json.com/api.json?rss_url=' .. URL.escape(input))
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if not string.match(jdat.status, 'ok') then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local output = '*' .. jdat.feed.title .. '*\n`[' .. jdat.items[1].pubDate:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/') .. ']` [' .. jdat.items[1].title .. '](' .. jdat.items[1].link .. ')'
	if jdat.items[2] then
		output = output .. '\n`[' .. jdat.items[2].pubDate:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/') .. ']` [' .. jdat.items[2].title .. '](' .. jdat.items[2].link .. ')'
	end
	if jdat.items[3] then
		output = output .. '\n`[' .. jdat.items[3].pubDate:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/') .. ']` [' .. jdat.items[3].title .. '](' .. jdat.items[3].link .. ')'
	end
	if jdat.items[4] then
		output = output .. '\n`[' .. jdat.items[4].pubDate:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/') .. ']` [' .. jdat.items[4].title .. '](' .. jdat.items[4].link .. ')'
	end
	if jdat.items[5] then
		output = output .. '\n`[' .. jdat.items[5].pubDate:gsub('%a+, ', ''):gsub(' %d%d:%d%d:%d%d %a+', ''):gsub(' Jan ', '/01/'):gsub(' Feb ', '/02/'):gsub(' Mar ', '/03/'):gsub(' Apr ', '/04/'):gsub(' May ', '/05/'):gsub(' Jun ', '/06/'):gsub(' Jul ', '/07/'):gsub(' Aug ', '/08/'):gsub(' Sep ', '/09/'):gsub(' Oct ', '/10/'):gsub(' Nov ', '/11/'):gsub(' Dec ', '/12/') .. ']` [' .. jdat.items[5].title .. '](' .. jdat.items[5].link .. ')'
	end
	local output_res = functions.send_reply(msg, output, true)
	if not output_res then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
end
return rss