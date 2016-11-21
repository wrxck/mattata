--[[

    Based on reddit.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local reddit = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function reddit:init(configuration)
	reddit.arguments = 'reddit <r/subreddit | query>'
	reddit.commands = mattata.commands(self.info.username, configuration.commandPrefix, {'^/r/'}):c('reddit'):c('r'):c('r/').table
	reddit.help = configuration.commandPrefix .. 'reddit <r/subreddit | query> Returns the top posts or results for a given subreddit or query. If no argument is given, the top posts from r/all are returned. Aliases: ' .. configuration.commandPrefix .. 'r, /r/subreddit.'
end

function formatResults(posts)
	local output = ''
	for _, v in ipairs(posts) do
		local post = v.data
		local title = post.title:gsub('%[', '('):gsub('%]', ')'):gsub('&amp;', '&')
		if title:len() > 256 then
			title = title:sub(1, 253)
			title = mattata.trim(title) .. '...'
		end
		local shortUrl = 'redd.it/' .. post.id
		local s = '[' .. title .. '](' .. shortUrl .. ')'
		if post.domain and not post.is_self and not post.over_18 then
			s = '`[`[' .. post.domain .. '](' .. post.url:gsub('%)', '\\)') .. ')`]` ' .. s
		end
		output = output .. '• ' .. s .. '\n'
	end
	return output
end

function reddit:onChannelPostReceive(channel_post, configuration)
	local text = channel_post.text_lower
	if text:match('^/r/.') then
		text = channel_post.text_lower:gsub('^/r/', configuration.commandPrefix .. 'r r/')
	end
	local input = mattata.input(text)
	local source, url
	if input then
		if not string.match(input, '/random') then
			if input:match('^r/.') then
				input = mattata.getWord(input, 1)
				url = 'https://www.reddit.com/%s/.json?limit='
				url = url:format(input) .. 8
				source = '*/' .. mattata.markdownEscape(input):gsub('\\', '') .. '*\n'
			else
				input = mattata.input(message.text)
				source = '*Results for* ' .. mattata.markdownEscape(input) .. '*:*\n'
				input = URL.escape(input)
				url = 'https://www.reddit.com/search.json?q=%s&limit='
				url = url:format(input) .. 8
			end
		else
			mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
			return
		end
	else
		url = 'https://www.reddit.com/.json?limit=' .. 8
		source = '*/r/all*\n'
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if #jdat.data.children == 0 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendMessage(channel_post.chat.id, source .. formatResults(jdat.data.children), 'Markdown', true, false, channel_post.message_id)
end

function reddit:onMessageReceive(message, configuration, language)
	local limit = 4
	if message.chat.type == 'private' then
		limit = 8
	end
	local text = message.text_lower
	if text:match('^/r/.') then
		text = message.text_lower:gsub('^/r/', configuration.commandPrefix .. 'r r/')
	end
	local input = mattata.input(text)
	local source, url
	if input then
		if not string.match(input, '/random') then
			if input:match('^r/.') then
				input = mattata.getWord(input, 1)
				url = 'https://www.reddit.com/%s/.json?limit='
				url = url:format(input) .. limit
				source = '*/' .. mattata.markdownEscape(input):gsub('\\', '') .. '*\n'
			else
				input = mattata.input(message.text)
				source = '*Results for* ' .. mattata.markdownEscape(input) .. '*:*\n'
				input = URL.escape(input)
				url = 'https://www.reddit.com/search.json?q=%s&limit='
				url = url:format(input) .. limit
			end
		else
			mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
			return
		end
	else
		url = 'https://www.reddit.com/.json?limit=' .. limit
		source = '*/r/all*\n'
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if #jdat.data.children == 0 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, source .. formatResults(jdat.data.children), 'Markdown', true, false, message.message_id)
end

return reddit