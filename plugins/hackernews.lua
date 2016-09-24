local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
local hackernews = {}
function hackernews:init(configuration)
	hackernews.command = 'hackernews'
	hackernews.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('hackernews', true):t('hn', true).table
	hackernews.doc = configuration.command_prefix .. 'hackernews - Sends the top stories from Hacker News. Alias: ' .. configuration.command_prefix .. 'hn'
	hackernews.topstories_url = 'https://hacker-news.firebaseio.com/v0/topstories.json'
	hackernews.res_url = 'https://hacker-news.firebaseio.com/v0/item/%s.json'
	hackernews.art_url = 'https://news.ycombinator.com/item?id=%s'
	hackernews.last_update = 0
end
local function get_hackernews_results()
	local results = {}
	local jstr, code = HTTPS.request(hackernews.topstories_url)
	if code ~= 200 then return end
	local data = JSON.decode(jstr)
	for i = 1, 8 do
		local ijstr, icode = HTTPS.request(hackernews.res_url:format(data[i]))
		if icode ~= 200 then return end
		local idata = JSON.decode(ijstr)
		local result
		if idata.url then
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> <a href="%s">%s</a>',
				functions.html_escape(hackernews.art_url:format(idata.id)),
				idata.id,
				functions.html_escape(idata.url),
				functions.html_escape(idata.title)
			)
		else
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> %s',
				functions.html_escape(hackernews.art_url:format(idata.id)),
				idata.id,
				functions.html_escape(idata.title)
			)
		end
		table.insert(results, result)
	end
	return results
end
function hackernews:action(msg, configuration)
	local now = os.time() / 60
	if not hackernews.results or hackernews.last_update + configuration.hackernews_interval < now then
		telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'typing' }
		hackernews.results = get_hackernews_results()
		if not hackernews.results then
			functions.send_reply(msg, configuration.errors.connection)
			return
		end
		hackernews.last_update = now
	end
	local res_count = msg.chat.id == msg.from.id and 8 or 4
	local output = '<b>Top Stories from Hacker News:</b>'
	for i = 1, res_count do
		output = output .. hackernews.results[i]
	end
	functions.send_message(msg.chat.id, output, true, nil, 'html')
end
return hackernews