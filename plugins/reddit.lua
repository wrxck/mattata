local reddit = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')
reddit.subreddit_url = 'https://www.reddit.com/%s/.json?limit='
reddit.search_url = 'https://www.reddit.com/search.json?q=%s&limit='
reddit.rall_url = 'https://www.reddit.com/.json?limit='

function reddit:init(configuration)
	reddit.arguments = 'reddit (r/subreddit | query)'
	reddit.commands = mattata.commands(self.info.username, configuration.commandPrefix, {'^/r/'}):c('reddit', true):c('r', true):c('r/', true).table
	reddit.help = configuration.commandPrefix .. 'reddit (r/subreddit | query) Returns the top posts or results for a given subreddit or query. If no argument is given, returns the top posts from r/all. Querying specific subreddits is not supported. Aliases: ' .. configuration.commandPrefix .. 'r, /r/subreddit.'
end

local function format_results(posts)
	local output = ''
	for _, v in ipairs(posts) do
		local post = v.data
		local title = post.title:gsub('%[', '('):gsub('%]', ')'):gsub('&amp;', '&')
		if title:len() > 256 then
			title = title:sub(1, 253)
			title = mattata.trim(title) .. '...'
		end
		local short_url = 'redd.it/' .. post.id
		local s = '[' .. title .. '](' .. short_url .. ')'
		if post.domain and not post.is_self and not post.over_18 then
			s = '`[`[' .. post.domain .. '](' .. post.url:gsub('%)', '\\)') .. ')`]` ' .. s
		end
		output = output .. '• ' .. s .. '\n'
	end
	return output
end

function reddit:onMessageReceive(msg, configuration)
	local limit = 4
	if msg.chat.type == 'private' then
		limit = 8
	end
	local text = msg.text_lower
	if text:match('^/r/.') then
		text = msg.text_lower:gsub('^/r/', configuration.commandPrefix .. 'r r/')
	end
	local input = mattata.input(text)
	local source, url
	if input then
		if not string.match(input, '/random') then
			if input:match('^r/.') then
				input = mattata.getWord(input, 1)
				url = reddit.subreddit_url:format(input) .. limit
				source = '*/' .. mattata.markdownEscape(input):gsub('\\', '') .. '*\n'
			else
				input = mattata.input(msg.text)
				source = '*Results for* _' .. mattata.markdownEscape(input) .. '_ *:*\n'
				input = URL.escape(input)
				url = reddit.search_url:format(input) .. limit
			end
		else
			mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
			return
		end
	else
		url = reddit.rall_url .. limit
		source = '*/r/all*\n'
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
	end
	local jdat = JSON.decode(jstr)
	if #jdat.data.children == 0 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
	else
		local output = format_results(jdat.data.children)
		output = source .. output
		mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
		return
	end
end

return reddit