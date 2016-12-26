local githubfeed = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function githubfeed:init(configuration)
	githubfeed.arguments = 'githubfeed <sub/del> <GitHub username> <GitHub repository name>'
	githubfeed.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('gh').table
end

function githubfeed.getRedis(id, option, extra)
	local ex = ''
	if option ~= nil then
		ex = ex .. ':' .. option
		if extra ~= nil then ex = ex .. ':' .. extra end
	end
	return 'github:' .. id .. ex
end

function githubfeed.checkFeed(repo, currentEtag, lastDate)
	local repoRequest = {
		url = 'https://api.github.com/repos/' .. repo,
		method = 'HEAD',
		redirect = false,
		sink = ltn12.sink.null(),
		headers = { Authorization = 'token ' .. configuration.keys.githubfeed, ['If-None-Match'] = currentEtag }
	}
	local res, code = https.request(repoRequest)
	if not res then return nil elseif code == 304 then return true end
	local body = {}
	local sinceRequest = {
		url = 'https://api.github.com/repos/' .. repo .. '/commits?since=' .. lastDate,
		method = 'GET',
		sink = ltn12.sink.table(body),
		headers = { Authorization = 'token ' .. configuration.keys.githubfeed }
	}
	local res, code, headers = https.request(sinceRequest)
	if not headers then return nil end
	local jdat = json.decode(table.concat(body))
	return false, jdat, headers.etag
end

function githubfeed.checkRepo(repo)
	local body = {}
	local request = {
		url = 'https://api.github.com/repos/' .. repo,
		method = 'GET',
		sink = ltn12.sink.table(body),
		headers = { Authorization = 'token ' .. configuration.keys.githubfeed }
	}
	local res, code, headers = https.request(request)
	if not res then return nil end
	return json.decode(table.concat(body)), headers.etag
end

function githubfeed.subscribe(id, repo)
	local lastHash = githubfeed.getRedis(repo, 'lastCommit')
	local lastEtag = githubfeed.getRedis(repo, 'etag')
	local lastDate = githubfeed.getRedis(repo, 'date')
	local lHash = githubfeed.getRedis(repo, 'subs')
	local userHash = githubfeed.getRedis(id)
	if redis:sismember(userHash, repo) then return 'You\'re already subscribed to changes made within that repository.' end
	local jdat, etag = githubfeed.checkRepo(repo)
	if not jdat or not jdat.full_name then return configuration.errors.results end
	if not etag then return 'Error' end
	local lastCommit = ''
	local pushedAt = jdat.pushed_at
	local name = jdat.full_name
	redis:set(lastHash, lastCommit)
	redis:set(lastDate, pushedAt)
	redis:set(lastEtag, etag)
	redis:sadd(lHash, id)
	redis:sadd(userHash, repo)
	return 'Subscribed to <b>' .. mattata.htmlEscape(name) .. '</b>! You will now receive updates for this repository right here, in this chat.'
end

function githubfeed.unsubscribe(id, n)
	if #n > 3 then return 'That\'s not a valid subscription ID.' end
	n = tonumber(n)
	local userHash = githubfeed.getRedis(id)
	local subs = redis:smembers(userHash)
	if n < 1 or n > #subs then return 'That\'s not a valid subscription ID.' end
	local sub = subs[n]
	local lHash = githubfeed.getRedis(sub, 'subs')
	redis:srem(userHash, sub)
	redis:srem(lHash, id)
	local left = redis:smembers(lHash)
	if #left < 1 then
		local lastEtag = githubfeed.getRedis(sub, 'etag')
		local lastDate = githubfeed.getRedis(sub, 'date')
		local lastHash = githubfeed.getRedis(sub, 'lastCommit')
		redis:del(lastEtag)
		redis:del(lastHash)
		redis:del(lastDate)
	end
	return 'You will no longer receive updates from <b>' .. mattata.htmlEscape(sub) .. '</b>!'
end

function githubfeed.getSubs(id, chatName)
	local userHash = githubfeed.getRedis(id)
	local subs = redis:smembers(userHash)
	if not subs[1] then return 'You don\'t appear to be subscribed to any GitHub repositories. Use \'' .. configuration.commandPrefix .. 'gh sub <username>/<repository>\' to set up your first subscription!' end
	local keyboard = {
		one_time_keyboard = true,
		selective = true,
		resize_keyboard = true
	}
	local buttons = {}
	local text = 'This chat is currently receiving updates for the following GitHub repositories:'
	for k, v in pairs(subs) do
		text = text .. string.format('\n%s: <a href="%s">%s</a>\n', mattata.htmlEscape(k), mattata.htmlEscape(v), v)
		table.insert(buttons, { text = configuration.commandPrefix .. 'gh del ' .. k })
	end
	keyboard.keyboard = { buttons, {{ text = 'Cancel' }}}
	return text, keyboard
end

function githubfeed:onMessage(message, configuration)
	if message.chat.type == 'private' or not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub') and not message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub$') then
		mattata.sendMessage(message.chat.id, githubfeed.subscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'gh sub ', ''):gsub(' ', '/')), 'HTML', true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'gh del') then
		mattata.sendMessage(message.chat.id, githubfeed.unsubscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'gh del ', ''):gsub(' ', '')), 'HTML', true, false, message.message_id)
	elseif message.text_lower == configuration.commandPrefix .. 'gh' then
		local output, keyboard = githubfeed.getSubs(message.chat.id, message.chat.id)
		mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
	elseif mattata.isConfiguredAdmin(message.from.id) and message.text_lower == configuration.commandPrefix .. 'gh reload' then
		local res = githubfeed:cron()
		if not res then return else mattata.sendMessage(message.chat.id, self.info.first_name .. ' is reloading...', nil) end
	end
end

function githubfeed:cron()
	local keys = redis:keys(githubfeed.getRedis('*', 'subs'))
	for k, v in pairs(keys) do
		local repo = v:match('github:(.+):subs')
		local currentEtag = redis:get(githubfeed.getRedis(repo, 'etag'))
		local lastDate = redis:get(githubfeed.getRedis(repo, 'date'))
		local noChanges, jdat, lastEtag = githubfeed.checkFeed(repo, currentEtag, lastDate)
		if not noChanges then
			if not jdat or not lastEtag then return end
			local lastCommit = redis:get(githubfeed.getRedis(repo, 'lastCommit')) 
			local text = ''
			for n in ipairs(jdat) do
				if jdat[n].sha ~= lastCommit then
					text = text .. string.format(
						'<b>%s has committed on</b> <a href="%s">%s</a>!\n<pre>%s</pre>',
						mattata.htmlEscape(jdat[n].commit.author.name),
						jdat[n].html_url,
						mattata.htmlEscape(repo),
						mattata.htmlEscape(jdat[n].commit.message)
					)
				end
			end
			if text ~= '' then
				local lastCommit = jdat[1].sha
				local lastDate = jdat[1].commit.author.date
				redis:set(githubfeed.getRedis(repo, 'lastCommit'), lastCommit)
				redis:set(githubfeed.getRedis(repo, 'etag'), lastEtag)
				redis:set(githubfeed.getRedis(repo, 'date'), lastDate)
				for key, recipient in pairs(redis:smembers(v)) do mattata.sendMessage(recipient, text, 'HTML', true) end
			end
		end
	end
	return true
end

return githubfeed