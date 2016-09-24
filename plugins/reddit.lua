local reddit = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function reddit:init(configuration)
	reddit.command = 'reddit (r/subreddit | query)'
	reddit.triggers = functions.triggers(self.info.username, configuration.command_prefix, {'^/r/'}):t('reddit', true):t('r', true):t('r/', true).table
	reddit.doc = configuration.command_prefix .. 'reddit (r/subreddit | query) Returns the top posts or results for a given subreddit or query. If no argument is given, returns the top posts from r/all. Querying specific subreddits is not supported. Aliases: ' .. configuration.command_prefix .. 'r, /r/subreddit'
end
local function format_results(posts)
	local output = ''
	for _,v in ipairs(posts) do
		local post = v.data
		local title = post.title:gsub('%[', '('):gsub('%]', ')'):gsub('&amp;', '&')
		if title:len() > 256 then
			title = title:sub(1, 253)
			title = functions.trim(title) .. '...'
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
reddit.subreddit_url = 'https://www.reddit.com/%s/.json?limit='
reddit.search_url = 'https://www.reddit.com/search.json?q=%s&limit='
reddit.rall_url = 'https://www.reddit.com/.json?limit='
function reddit:action(msg, configuration)
	local limit = 4
	if msg.chat.type == 'private' then
		limit = 8
	end
	local text = msg.text_lower
	if text:match('^/r/.') then
		text = msg.text_lower:gsub('^/r/', configuration.command_prefix..'r r/')
	end
	local input = functions.input(text)
	local source, url
	if input then
		if input:match('^r/.') then
			input = functions.get_word(input, 1)
			url = reddit.subreddit_url:format(input) .. limit
			source = '*/' .. functions.md_escape(input):gsub('\\', '') .. '*\n'
		else
			input = functions.input(msg.text)
			source = '*Results for* _' .. functions.md_escape(input) .. '_ *:*\n'
			input = URL.escape(input)
			url = reddit.search_url:format(input) .. limit
		end
	else
		url = reddit.rall_url .. limit
		source = '*/r/all*\n'
	end
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
	else
		local jdat = JSON.decode(jstr)
		if #jdat.data.children == 0 then
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
		else
			local output = format_results(jdat.data.children)
			output = source .. output
			functions.send_reply(msg, output, true)
		end
	end
end
return reddit
