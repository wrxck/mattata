--[[

    Based on hackernews.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local hackernews = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')

hackernews.topstories = 'https://hacker-news.firebaseio.com/v0/topstories.json'
hackernews.res = 'https://hacker-news.firebaseio.com/v0/item/%s.json'
hackernews.art = 'https://news.ycombinator.com/item?id=%s'

function hackernews:init(configuration)
	hackernews.arguments = 'hackernews'
	hackernews.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('hackernews'):c('hn').table
	hackernews.inlineCommands = hackernews.commands
	hackernews.help = configuration.commandPrefix .. 'hackernews - Sends the top stories from Hacker News. Alias: ' .. configuration.commandPrefix .. 'hn.'
	hackernews.lastUpdate = 0
end

function getHackernewsResults(language)
	local results = {}
	local jstr, res = HTTPS.request(hackernews.topstories)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	for i = 1, 8 do
		local ijstr, ires = HTTPS.request(hackernews.res:format(jdat[i]))
		if ires ~= 200 then
			mattata.sendMessage(message, language.errors.connection, nil, true, false, message.message_id)
			return
		end
		local ijdat = JSON.decode(ijstr)
		local result
		if ijdat.url then
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> <a href="%s">%s</a>',
				mattata.htmlEscape(hackernews.art:format(ijdat.id)),
				ijdat.id,
				mattata.htmlEscape(ijdat.url),
				mattata.htmlEscape(ijdat.title)
			)
		else
			result = string.format(
				'\n• <code>[</code><a href="%s">%s</a><code>]</code> %s',
				mattata.htmlEscape(hackernews.art:format(ijdat.id)),
				ijdat.id,
				mattata.htmlEscape(ijdat.title)
			)
		end
		table.insert(results, result)
	end
	return results
end

function hackernews:onMessage(message, language)
	local now = os.time() / 60
	if not hackernews.results then
		hackernews.results = getHackernewsResults(language)
		if not hackernews.results then
			mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
			return
		end
		hackernews.lastUpdate = now
	end
	local resultCount = message.chat.id == message.from.id and 8 or 4
	local output = '<b>Top Stories from Hacker News:</b>'
	for i = 1, resultCount do
		output = output .. hackernews.results[i]
	end
	mattata.sendChatAction(message.chat.id, 'typing')
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
end

return hackernews