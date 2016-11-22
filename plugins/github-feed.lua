local gh = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local ltn12 = require('ltn12')
local JSON = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')
local token = configuration.keys.github_feed

function gh:init(configuration)
	gh.arguments = 'gh <sub/del> <GitHub username> <GitHub repository name>'
	gh.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('gh').table
end

function getRedis(id, option, extra)
	local ex = ''
	if option ~= nil then
		ex = ex .. ':' .. option
		if extra ~= nil then
			ex = ex .. ':' .. extra
		end
	end
	return 'github:' .. id .. ex
end

function checkFeed(repo, currentEtag, lastDate)
	local url = 'https://api.github.com/repos/' .. repo
	local buildRequest = {
		url = url,
		method = 'HEAD',
		redirect = false,
		sink = ltn12.sink.null(),
		headers = {
			Authorization = 'token ' .. token,
			['If-None-Match'] = currentEtag
		}
	}
	local ok, responseCode = HTTPS.request(buildRequest)
	if not ok then
		return nil
	end
	if responseCode == 304 then
		return true
	end
	local url = 'https://api.github.com/repos/' .. repo .. '/commits?since=' .. lastDate
	local responseBody = {}
	local buildRequest = {
		url = url,
		method = 'GET',
		sink = ltn12.sink.table(responseBody),
		headers = {
			Authorization = 'token ' .. token
		}
	}
	local ok, responseCode, responseHeaders = HTTPS.request(buildRequest)
	if not responseHeaders then
		return nil
	end
	local data = JSON.decode(table.concat(responseBody))
	return false, data, responseHeaders.etag
end

function gh:checkRepo(repo)
	local url = 'https://api.github.com/repos/' .. repo
	local responseBody = {}
	local buildRequest = {
		url = url,
		method = 'GET',
		sink = ltn12.sink.table(responseBody),
		headers = {
			Authorization = 'token ' .. token
		}
	}
	local ok, responseCode, responseHeaders = HTTPS.request(buildRequest)
	if not ok then
		return nil
	end
	return JSON.decode(table.concat(responseBody)), responseHeaders.etag
end

function gh:subscribe(id, repo)
	local lastHash = getRedis(repo, 'lastCommit')
	local lastEtag = getRedis(repo, 'etag')
	local lastDate = getRedis(repo, 'date')
	local lHash = getRedis(repo, 'subs')
	local userHash = getRedis(id)
	if redis:sismember(userHash, repo) then
		return 'You\'re already subscribed to changes made within that repository.'
	end
	local data, etag = gh:checkRepo(repo)
	if not data or not data.full_name then
		return configuration.errors.results
	end
	if not etag then
		return 'Error2'
	end
	local lastCommit = ''
	local pushedAt = data.pushed_at
	local name = data.full_name
	redis:set(lastHash, lastCommit)
	redis:set(lastDate, pushedAt)
	redis:set(lastEtag, etag)
	redis:sadd(lHash, id)
	redis:sadd(userHash, repo)
	return 'Subscribed to *' .. name .. '*! You will now receive updates for this repository right here, in this chat.'
end

function gh:unsubscribe(id, n)
	if #n > 3 then
		return 'That\'s not a valid subscription ID.'
	end
	n = tonumber(n)
	local userHash = getRedis(id)
	local subs = redis:smembers(userHash)
	if n < 1 or n > #subs then
		return 'That\'s not a valid subscription ID.'
	end
	local sub = subs[n]
	local lHash = getRedis(sub, 'subs')
	redis:srem(userHash, sub)
	redis:srem(lHash, id)
	local left = redis:smembers(lHash)
	if #left < 1 then
		local lastEtag = getRedis(sub, 'etag')
		local lastDate = getRedis(sub, 'date')
		local lastHash = getRedis(sub, 'lastCommit')
		redis:del(lastEtag)
		redis:del(lastHash)
		redis:del(lastDate)
	end
	return 'You will no longer receive updates from *' .. sub .. '*!'
end

function gh:getSubs(id, chatName)
	local userHash = getRedis(id)
	local subs = redis:smembers(userHash)
	if not subs[1] then
		return 'You don\'t appear to be subscribed to any GitHub repositories. Use \'' .. configuration.commandPrefix .. 'gh sub <username>/<repository>\' to set up your first subscription!'
	end
	local keyboard = '{"keyboard":[['
	local buttons = ''
	local text = chatName
	for k, v in pairs(subs) do
		text = text .. '\n' .. k .. ': [' .. v .. '](https://github.com/' .. v .. ')\n'
		if k == #subs then
			buttons = buttons .. '{"text":"/gh del ' .. k .. '"}'
			break;
		end
		buttons = buttons .. '{"text":"/gh del ' .. k .. '"},'
	end
	local keyboard = keyboard .. buttons .. ',{"text":"Cancel"}]], "one_time_keyboard":true, "selective":true, "resize_keyboard":true}'
	return text, keyboard
end

function gh:onChannelPost(channel_post, configuration)
	if channel_post.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub') then
		if not channel_post.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub$') then
			mattata.sendMessage(channel_post.chat.id, gh:subscribe(channel_post.chat.id, channel_post.text_lower:gsub(configuration.commandPrefix .. 'gh sub ', ''):gsub(' ', '/')), 'Markdown', true, false, channel_post.message_id)
			return
		end
	end
	if string.match(channel_post.text_lower, '^' .. configuration.commandPrefix .. 'gh del') then
		mattata.sendMessage(channel_post.chat.id, gh:unsubscribe(channel_post.chat.id, channel_post.text_lower:gsub(configuration.commandPrefix .. 'gh del ', ''):gsub(' ', '')), 'Markdown', true, false, channel_post.message_id)
		return
	end
	if channel_post.text_lower == configuration.commandPrefix .. 'gh' then
		local output, keyboard = gh:getSubs(channel_post.chat.id, channel_post.chat.title)
		mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id, keyboard)
		return
	end
end

function gh:onMessage(message, configuration, self)
	if message.chat.type == 'private' then
		return
	elseif not mattata.isGroupAdmin(message.chat.id, message.from.id) or not mattata.isConfiguredAdmin(message.from.id) then
		return
	end
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub') then
		if not message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub$') then
			mattata.sendMessage(message.chat.id, gh:subscribe(message.chat.id, message.text_lower:gsub(configuration.commandPrefix .. 'gh sub ', ''):gsub(' ', '/')), 'Markdown', true, false, message.message_id)
			return
		end
	end
	if string.match(message.text, '^' .. configuration.commandPrefix .. 'gh del') then
		mattata.sendMessage(message.chat.id, gh:unsubscribe(message.chat.id, message.text_lower:gsub(configuration.commandPrefix .. 'gh del ', ''):gsub(' ', '')), 'Markdown', true, false, message.message_id)
		return
	end
	if message.text_lower == configuration.commandPrefix .. 'gh' then
		local output, keyboard = gh:getSubs(message.chat.id, message.chat.id)
		mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, keyboard)
		return
	end
	if mattata.isConfiguredAdmin(message.from.id) then
		if message.text_lower == configuration.commandPrefix .. 'gh reload' then
			local res = gh:cron()
			if res then
				mattata.sendMessage(message.chat.id, self.info.username .. ' is reloading...', nil)
			end
		end
	end
end

function gh:cron()
	local keys = redis:keys(getRedis('*', 'subs'))
	for k, v in pairs(keys) do
		local repo = string.match(v, 'github:(.+):subs')
		local currentEtag = redis:get(getRedis(repo, 'etag'))
		local lastDate = redis:get(getRedis(repo, 'date'))
		local noChanges, data, lastEtag = checkFeed(repo, currentEtag, lastDate)
		if not noChanges then
			if not data or not lastEtag then
				return
			end
			local lastCommit = redis:get(getRedis(repo, 'lastCommit')) 
			local text = ''
			for n in ipairs(data) do
				if data[n].sha ~= lastCommit then
					local author = data[n].commit.author.name
					local message = data[n].commit.message
					local link = data[n].html_url
					text = text .. '*New commit on* [' .. repo .. '](' .. link .. ')!\n```\n' .. message .. '\n```By ' .. mattata.markdownEscape(author) .. '\n\n'
				end
			end
			if text ~= '' then
				local lastCommit = data[1].sha
				local lastDate = data[1].commit.author.date
				redis:set(getRedis(repo, 'lastCommit'), lastCommit)
				redis:set(getRedis(repo, 'etag'), lastEtag)
				redis:set(getRedis(repo, 'date'), lastDate)
				for key, recipient in pairs(redis:smembers(v)) do
					mattata.sendMessage(recipient, text, 'Markdown', true)
				end
			end
		end
	end
end

return gh