local hackernews = {}
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local functions = require('functions')
function hackernews:init(configuration)
	hackernews.command = 'hackernews'
	hackernews.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('hackernews', true):t('hn', true).table
	hackernews.documentation = configuration.command_prefix .. 'hackernews - Sends the top stories from Hacker News. Alias: ' .. configuration.command_prefix .. 'hn.'
	hackernews.last_update = 0
end
local function get_hackernews_results(configuration)
	local results = {}
	local jstr, res = HTTPS.request(configuration.apis.hackernews.topstories)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	for i = 1, 8 do
		local ijstr, ires = HTTPS.request(configuration.apis.hackernews.res:format(jdat[i]))
		if ires ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		end
		local ijdat = JSON.decode(ijstr)
		local result
		if ijdat.url then
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> <a href="%s">%s</a>',
				functions.html_escape(configuration.apis.hackernews.art:format(ijdat.id)),
				ijdat.id,
				functions.html_escape(ijdat.url),
				functions.html_escape(ijdat.title)
			)
		else
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> %s',
				functions.html_escape(configuration.apis.hackernews.art:format(ijdat.id)),
				ijdat.id,
				functions.html_escape(ijdat.title)
			)
		end
		table.insert(results, result)
	end
	return results
end
function hackernews:action(msg, configuration)
	local now = os.time() / 60
	if not hackernews.results then
		hackernews.results = get_hackernews_results(configuration)
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
	functions.send_action(msg.chat.id, 'typing')
	functions.send_message(msg.chat.id, output, true, nil, 'html')
end
return hackernews