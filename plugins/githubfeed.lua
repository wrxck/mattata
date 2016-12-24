local githubfeed = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local JSON = require('dkjson')
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
	local request = {
		url = 'https://api.github.com/repos/' .. repo,
		method = 'HEAD',
		redirect = false,
		sink = ltn12.sink.null(),
		headers = { Authorization = 'token ' .. configuration.keys.githubfeed, ['If-None-Match'] = currentEtag }
	}
	local res, code = HTTPS.request(request)
	if not res then return nil elseif code == 304 then return true end
	local body = {}
	local buildRequest = {
		url = 'https://api.github.com/repos/' .. repo .. '/commits?since=' .. lastDate,
		method = 'GET',
		sink = ltn12.sink.table(body),
		headers = { Authorization = 'token ' .. configuration.keys.githubfeed }
	}
	local res, code, headers = HTTPS.request(request)
	if not headers then return nil end
	local jdat = JSON.decode(table.concat(body))
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
	local res, code, headers = HTTPS.request(request)
	if not res then return nil end
	return JSON.decode(table.concat(body)), headers.etag
end

function githubfeed.subscribe(id, repo)
	local configuration = require('configuration')
	local lastHash = githubfeed.getRedis(repo, 'lastCommit')
	local lastEtag = githubfeed.getRedis(repo, 'etag')
	local lastDate = githubfeed.getRedis(repo, 'date')
	local lHash = githubfeed.getRedis(repo, 'subs')
	local userHash = githubfeed.getRedis(id)
	if redis:sismember(userHash, repo) then return 'You\'re already subscribed to changes made within that repository.' end
	local jdat, etag = githubfeed.checkRepo(repo)
	if not jdat or not jdat.full_name then return configuration.errors.results end
	if not etag then return 'Error2' end
	local lastCommit = ''
	local pushedAt = jdat.pushed_at
	local name = jdat.full_name
	redis:set(lastHash, lastCommit)
	redis:set(lastDate, pushedAt)
	redis:set(lastEtag, etag)
	redis:sadd(lHash, id)
	redis:sadd(userHash, repo)
	return 'Subscribed to *' .. name .. '*! You will now receive updates for this repository right here, in this chat.'
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
	return 'You will no longer receive updates from *' .. sub .. '*!'
end

function githubfeed.getSubs(id, chatName)
	local userHash = githubfeed.getRedis(id)
	local subs = redis:smembers(userHash)
	if not subs[1] then return 'You don\'t appear to be subscribed to any GitHub repositories. Use \'' .. configuration.commandPrefix .. 'gh sub <username>/<repository>\' to set up your first subscription!' end
	local keyboard = {
		one_time_keyboard = true,
		selective = true,
		resize_keyboard_keyboard = true
	}
	local buttons = {}
	local text = 'This chat is currently receiving updates for the following GitHub repositories:'
	for k, v in pairs(subs) do
		text = text .. '\n' .. k .. ': [' .. v .. '](https://github.com/' .. v .. ')\n'
		table.insert(buttons, { text = configuration.commandPrefix .. 'gh del ' .. k })
	end
	keyboard.keyboard = { buttons, {{ text = 'Cancel' }}}
	return text, keyboard
end

function githubfeed:onMessage(message, configuration)
	if message.chat.type == 'private' or not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub') and not message.text_lower:match('^' .. configuration.commandPrefix .. 'gh sub$') then
		mattata.sendMessage(message.chat.id, githubfeed.subscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'gh sub ', ''):gsub(' ', '/')), 'Markdown', true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'gh del') then
		mattata.sendMessage(message.chat.id, githubfeed.unsubscribe(message.chat.id, message.text_lower:gsub('^' .. configuration.commandPrefix .. 'gh del ', ''):gsub(' ', '')), 'Markdown', true, false, message.message_id)
	elseif message.text_lower == configuration.commandPrefix .. 'gh' then
		local output, keyboard = githubfeed.getSubs(message.chat.id, message.chat.id)
		mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
	elseif mattata.isConfiguredAdmin(message.from.id) and message.text_lower == configuration.commandPrefix .. 'gh reload' then
		local res = githubfeed:cron()
		if res then mattata.sendMessage(message.chat.id, self.info.username .. ' is reloading...', nil) end
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
			for n in ipairs(jdat) do if jdat[n].sha ~= lastCommit then text = text .. '*New commit on* [' .. repo .. '](' .. jdat[n].html_url .. ')!\n```\n' .. jdat[n].commit.message .. '\n```By ' .. mattata.markdownEscape(jdat[n].commit.author.name) .. '\n\n' end end
			if text ~= '' then
				local lastCommit = jdat[1].sha
				local lastDate = jdat[1].commit.author.date
				redis:set(githubfeed.getRedis(repo, 'lastCommit'), lastCommit)
				redis:set(githubfeed.getRedis(repo, 'etag'), lastEtag)
				redis:set(githubfeed.getRedis(repo, 'date'), lastDate)
				for key, recipient in pairs(redis:smembers(v)) do mattata.sendMessage(recipient, text, 'Markdown', true) end
			end
		end
	end
end

return githubfeed