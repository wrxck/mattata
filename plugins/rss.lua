local rss = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local redis = require('mattata-redis')
local feedparser = require('feedparser')
local configuration = require('configuration')

function rss:init(configuration)
	rss.arguments = 'rss <sub/del> <RSS feed url>'
	rss.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('rss').table
end

function rss.tail(n, k)
	local u, r = ''
	for i = 1, k do
		n, r = math.floor(n / 0x40), n % 0x40
		u = string.char(r + 0x80) .. u
	end
	return u, n
end
 
function rss.toUtf8(a)
	local n, r, u = tonumber(a)
	if n < 0x80 then
		return string.char(n)
	elseif n < 0x800 then
		u, n = rss.tail(n, 1)
		return string.char(n + 0xc0) .. u
	elseif n < 0x10000 then
		u, n = rss.tail(n, 2)
		return string.char(n + 0xe0) .. u
	elseif n < 0x200000 then
		u, n = rss.tail(n, 3)
		return string.char(n + 0xf0) .. u
	elseif n < 0x4000000 then
		u, n = rss.tail(n, 4)
		return string.char(n + 0xf8) .. u
	else
		u, n = rss.tail(n, 5)
		return string.char(n + 0xfc) .. u
	end
end

function rss.unescapeHtml(str)
	return str:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&quot;', '"'):gsub('&apos;', '\''):gsub('&#(%d+);', rss.toUtf8):gsub('&#x(%d+);', function(n) return string.char(tonumber(n, 16)) end):gsub('&amp;', '&')
end

function rss.getRedisHash(id, option, extra)
	local ex = ''
	if option ~= nil then
		ex = ex .. ':' .. option
		if extra ~= nil then
			ex = ex .. ':' .. extra
		end
	end
	return 'rss:' .. id .. ex
end

function rss.urlProtocol(url)
	local url, http = url:gsub('http://', '')
	local url, https = url:gsub('https://', '')
	local protocol = 'http'
	if https == 1 then protocol = protocol .. 's' end
	return url, protocol
end

function rss.getParsedFeed(url, protocol)
	local feed, res = nil, 0
	if protocol == 'http' then
		feed, res = http.request(url)
	elseif protocol == 'https' then
		feed, res = https.request(url)
	end
	if res ~= 200 then
		return nil, 'There was an error whilst connecting to ' .. url
	end
	local parseFeed = feedparser.parse(feed)
	if parseFeed == nil then
		return nil, 'There was an error retrieving a valid RSS feed from that url. Please, make sure you typed it correctly, and try again.'
	end
	return parseFeed, nil
end

function rss.getNewFeedEntries(last, parsedEntries)
	local entries = {}
	for k, v in pairs(parsedEntries) do
		if v.id == last then
			return entries
		else
			table.insert(entries, v)
		end
	end
	return entries
end

function rss.subscribe(id, url)
	local baseUrl, protocol = rss.urlProtocol(url)
	local protocolHash = rss.getRedisHash(baseUrl, 'protocol')
	local lastFeedEntryHash = rss.getRedisHash(baseUrl, 'lastEntry')
	local lhash = rss.getRedisHash(baseUrl, 'subscriptions')
	local uhash = rss.getRedisHash(id)
	if redis:sismember(uhash, baseUrl) then
      return 'You are already subscribed to ' .. url
	end
	local parsedFeed, res = rss.getParsedFeed(url, protocol)
	if res ~= nil then
		return res
	end
	local lastEntry = ''
	if #parsedFeed.entries > 0 then
		lastEntry = parsedFeed.entries[1].id
	end
	local name = parsedFeed.feed.title
	redis:set(protocolHash, protocol)
	redis:set(lastFeedEntryHash, lastEntry)
	redis:sadd(lhash, id)
	redis:sadd(uhash, baseUrl)
	return 'You are now subscribed to <a href="' .. url .. '">' .. mattata.htmlEscape(name) .. '</a> - you will receive updates for this feed right here in this chat!'
end

function rss.unsubscribe(id, n)
	if #n > 5 then
		return 'You cannot subscribe to more than 5 RSS feeds!'
	end
	n = tonumber(n)
	local uhash = rss.getRedisHash(id)
	local subscriptions = redis:smembers(uhash)
	if n < 1 or n > #subscriptions then
		return 'Please enter a valid subscription ID.'
	end
	local subscription = subscriptions[n]
	local lhash = rss.getRedisHash(subscription, 'subscriptions')
	redis:srem(uhash, subscription)
	redis:srem(lhash, id)
	local unsubscribed = redis:smembers(lhash)
	if #unsubscribed < 1 then
		redis:del(rss.getRedisHash(subscription, 'protocol'))
		redis:del(rss.getRedisHash(subscription, 'lastEntry'))
	end
	return 'You will no longer receive updates from this feed.'
end

function rss.getSubscriptions(id)
	local subscriptions = redis:smembers(rss.getRedisHash(id))
	if not subscriptions[1] then
		return 'You are not subscribed to any RSS feeds!'
	end
	local keyboard = {
		one_time_keyboard = true,
		selective = true,
		resize_keyboard_keyboard = true
	}
	local buttons = {}
	local text = 'This chat is currently receiving updates for the following RSS feeds:'
	for k, v in pairs(subscriptions) do
		text = text .. '\n' .. k .. ': ' .. v .. '\n'
		table.insert(buttons, { text = configuration.commandPrefix .. 'rss del ' .. k })
	end
	keyboard.keyboard = {
		buttons, {
			{ text = 'Cancel' }
		}
	}
	return text, json.encode(keyboard)
end

function rss:onMessage(message, configuration)
	if message.chat.type == 'private' or not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then
		return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'rss sub') and not message.text_lower:match('^' .. configuration.commandPrefix .. 'rss sub$') then
		mattata.sendMessage(message.chat.id, rss.subscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'rss sub ', '')), 'HTML', true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'rss sub$') then
		mattata.sendMessage(message.chat.id, 'Please specify the url of the RSS feed you would like to receive updates from.', nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'rss del') and not message.text_lower:match('^' .. configuration.commandPrefix .. 'rss del$') then
		mattata.sendMessage(message.chat.id, rss.unsubscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'rss del ', '')), nil, true, false, message.message_id)
	elseif message.text_lower == configuration.commandPrefix .. 'rss' or message.text_lower:match('^' .. configuration.commandPrefix .. 'rss del$') then
		local output, keyboard = rss.getSubscriptions(message.chat.id)
		mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, keyboard)
	elseif mattata.isConfiguredAdmin(message.from.id) and message.text_lower == configuration.commandPrefix .. 'rss reload' then
		local res = rss:cron()
		if res then mattata.sendMessage(message.chat.id, self.info.username .. ' is reloading...', nil) end
	else
		mattata.sendMessage(message.chat.id, configuration.commandPrefix .. rss.arguments, nil, true, false, message.message_id)
	end
end

function rss:cron()
	local keys = redis:keys(rss.getRedisHash('*', 'subscriptions'))
	for k, v in pairs(keys) do
		local base = v:match('rss:(.+):subs')
		local protocol = redis:get(rss.getRedisHash(base, 'protocol'))
		local last = redis:get(rss.getRedisHash(base, 'lastEntry'))
		local url = protocol .. '://' .. base
		local parsedFeed, res = rss.getParsedFeed(url, protocol)
		if res ~= nil then return end
		local newEntries = rss.getNewFeedEntries(last, parsedFeed.entries)
		local text = ''
		for l, w in pairs(newEntries) do
			local title = w.title or 'No title'
			local link = w.link or w.id or 'No link'
			if w.content then
				content = w.content:gsub('<br>', '\n'):gsub('%b<>', '')
				if w.content:len() > 500 then
					content = rss.unescapeHtml(content):sub(1, 500) .. '...'
				else
					content = rss.unescapeHtml(content)
				end
			elseif w.summary then
				content = w.summary:gsub('<br>', '\n'):gsub('%b<>', '')
				if w.summary:len() > 500 then
					content = rss.unescapeHtml(content):sub(1, 500) .. '...'
				else
					content = rss.unescapeHtml(content)
				end
			else
				content = ''
			end
			text = text .. '#' .. l .. ': <b>' .. mattata.htmlEscape(title) .. '</b>\n<i>' .. mattata.htmlEscape(mattata.trim(content)) .. '</i>\n<a href="' .. link .. '">Read more.</a>\n\n'
			if l == 5 then break; end
		end
		if text ~= '' then
			local newLastEntry = newEntries[1].id
			redis:set(rss.getRedisHash(base, 'lastEntry'), newLastEntry)
			for l, r in pairs(redis:smembers(v)) do
				mattata.sendChatAction(r, 'typing')
				mattata.sendMessage(r, text, 'HTML', true)
			end
		end
	end
end

return rss