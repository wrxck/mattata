--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local githubfeed = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function githubfeed:init(configuration)
    githubfeed.arguments = 'gh <sub | del> <username> <repository name>'
    githubfeed.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('gh').table
end

function githubfeed.get_redis_hash(id, option, extra)
    local ex = ''
    if option ~= nil then
        ex = ex .. ':' .. option
        if extra ~= nil then
            ex = ex .. ':' .. extra
        end
    end
    return 'github:' .. id .. ex
end

function githubfeed.check_feed(repo, current_etag, last_date)
    local res, code = https.request(
        {
            ['url'] = 'https://api.github.com/repos/' .. repo,
            ['method'] = 'HEAD',
            ['redirect'] = false,
            ['sink'] = ltn12.sink.null(),
            ['headers'] = {
                ['Authorization'] = 'token ' .. configuration.keys.githubfeed,
                ['If-None-Match'] = current_etag
            }
        }
    )
    if not res then
        return true
    elseif code == 304 then
        return true
    end
    local body = {}
    local res, code, headers = https.request(
        {
            ['url'] = 'https://api.github.com/repos/' .. repo .. '/commits?since=' .. last_date,
            ['method'] = 'GET',
            ['headers'] = {
                ['Authorization'] = 'token ' .. configuration.keys.githubfeed
            },
            ['sink'] = ltn12.sink.table(body)
        }
    )
    if not headers then
        return true
    end
    local jdat = json.decode(table.concat(body))
    return false, jdat, headers.etag
end

function githubfeed.check_repo(repo)
    local body = {}
    local res, code, headers = https.request(
        {
            ['url'] = 'https://api.github.com/repos/' .. repo,
            ['method'] = 'GET',
            ['headers'] = {
                ['Authorization'] = 'token ' .. configuration.keys.githubfeed
            },
            ['sink'] = ltn12.sink.table(body)
        }
    )
    if not res then
        return
    end
    return json.decode(table.concat(body)), headers.etag
end

function githubfeed.subscribe(id, repo)
    local last_hash = githubfeed.get_redis_hash(
        repo,
        'last_commit'
    )
    local last_etag = githubfeed.get_redis_hash(
        repo,
        'etag'
    )
    local last_date = githubfeed.get_redis_hash(
        repo,
        'date'
    )
    local subscriptions = githubfeed.get_redis_hash(
        repo,
        'subs'
    )
    local chat = githubfeed.get_redis_hash(id)
    if redis:sismember(
        chat,
        repo
    ) then
        return 'You\'re already subscribed to changes made within that repository.'
    end
    local jdat, etag = githubfeed.check_repo(repo)
    if not jdat or not jdat.full_name then
        return configuration.errors.results
    end
    if not etag then
        return 'An error occured.'
    end
    local last_commit = ''
    local pushed_at = jdat.pushed_at
    local name = jdat.full_name
    redis:set(last_hash, last_commit)
    redis:set(last_date, pushed_at)
    redis:set(last_etag, etag)
    redis:sadd(subscriptions, id)
    redis:sadd(chat, repo)
    return 'Subscribed to <b>' .. mattata.escape_html(name) .. '</b>! You will now receive updates for this repository right here, in this chat.'
end

function githubfeed.unsubscribe(id, n)
    if #n > 3 then
        return 'That\'s not a valid subscription ID.'
    end
    n = tonumber(n)
    local chat = githubfeed.get_redis_hash(id)
    local subs = redis:smembers(chat)
    if n < 1 or n > #subs then
        return 'That\'s not a valid subscription ID.'
    end
    local sub = subs[n]
    local subscriptions = githubfeed.get_redis_hash(sub, 'subs')
    redis:srem(
        chat,
        sub
    )
    redis:srem(
        subscriptions,
        id
    )
    local left = redis:smembers(subscriptions)
    if #left < 1 then
        local last_etag = githubfeed.get_redis_hash(
            sub,
            'etag'
        )
        local last_date = githubfeed.get_redis_hash(
            sub,
            'date'
        )
        local last_commit = githubfeed.get_redis_hash(
            sub,
            'last_commit'
        )
        redis:del(last_etag)
        redis:del(last_commit)
        redis:del(last_date)
    end
    return 'You will no longer receive updates from <b>' .. mattata.escape_html(sub) .. '</b>!'
end

function githubfeed.get_subs(id)
    local chat = githubfeed.get_redis_hash(id)
    local subs = redis:smembers(chat)
    if not subs[1] then
        return 'You don\'t appear to be subscribed to any GitHub repositories. Use \'' .. configuration.command_prefix .. 'gh sub <username>/<repository>\' to set up your first subscription!'
    end
    local keyboard = {
        ['one_time_keyboard'] = true,
        ['selective'] = true,
        ['resize_keyboard'] = true
    }
    local buttons = {}
    local text = 'This chat is currently receiving updates for the following GitHub repositories:'
    for k, v in pairs(subs) do
        text = text .. string.format(
            '\n%s: <a href="%s">%s</a>\n',
            mattata.escape_html(k),
            mattata.escape_html(v),
            v
        )
        table.insert(
            buttons,
            {
                ['text'] = configuration.command_prefix .. 'gh del ' .. k
            }
        )
    end
    keyboard.keyboard = {
        buttons,
        {
            {
                ['text'] = 'Cancel'
            }
        }
    }
    return text, keyboard
end

function githubfeed:on_message(message, configuration)
    if message.chat.type == 'private' and not mattata.is_global_admin(message.from.id) then
    	return mattata.send_reply(
    		message,
    		'You can\'t use this command in private chat!'
    	)
	elseif not mattata.is_global_admin(message.from.id) and not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(
        	message,
        	'You must be an administrator of this chat to use this command!'
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'gh sub') and not message.text_lower:match('^' .. configuration.command_prefix .. 'gh sub$') then
        return mattata.send_reply(
            message,
            githubfeed.subscribe(
                message.chat.id,
                message.text_lower:match('^' .. configuration.command_prefix .. 'gh sub (.-)$'):gsub(' ', '/')
            ),
            'html'
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'gh del') then
        return mattata.send_reply(
            message,
            githubfeed.unsubscribe(
                message.chat.id,
                message.text_lower:match('^' .. configuration.command_prefix .. 'gh del (.-)$'):gsub(' ', '')
            ),
            'html'
        )
    elseif mattata.is_global_admin(message.from.id) and message.text_lower:match('^' .. configuration.command_prefix .. 'gh reload') then
    	return githubfeed:cron()
	else
        local output, keyboard = githubfeed.get_subs(message.chat.id)
        return mattata.send_message(
            message.chat.id,
            output,
            'html',
            true,
            false,
            message.message_id,
            json.encode(keyboard)
        )
    end
end

function githubfeed:cron()
    local keys = redis:keys(
        githubfeed.get_redis_hash(
            '*',
            'subs'
        )
    )
    for k, v in pairs(keys) do
        local repo = v:match('github:(.+):subs')
        local current_etag = redis:get(
            githubfeed.get_redis_hash(
                repo,
                'etag'
            )
        )
        local last_date = redis:get(
            githubfeed.get_redis_hash(
                repo,
                'date'
            )
        )
        local no_changes, jdat, last_etag = githubfeed.check_feed(
            repo,
            current_etag,
            last_date
        )
        if not no_changes then
            if not jdat or not last_etag then
                return
            end
            local last_commit = redis:get(
                githubfeed.get_redis_hash(
                    repo,
                    'last_commit'
                )
            ) 
            local text = ''
            for n in ipairs(jdat) do
                if jdat[n].sha ~= last_commit then
                    text = text .. string.format(
                        '<b>%s has committed on</b> <a href="%s">%s</a>!\n<pre>%s</pre>\n\n',
                        mattata.escape_html(jdat[n].commit.author.name),
                        jdat[n].html_url,
                        mattata.escape_html(repo),
                        mattata.escape_html(jdat[n].commit.message)
                    )
                end
            end
            if text ~= '' then
                local last_commit = jdat[1].sha
                local last_date = jdat[1].commit.author.date
                redis:set(
                    githubfeed.get_redis_hash(
                        repo,
                        'last_commit'
                    ),
                    last_commit
                )
                redis:set(
                    githubfeed.get_redis_hash(
                        repo,
                        'etag'
                    ),
                    last_etag
                )
                redis:set(
                    githubfeed.get_redis_hash(
                        repo,
                        'date'
                    ),
                    last_date
                )
                for key, recipient in pairs(redis:smembers(v)) do
                    mattata.send_message(
                        recipient,
                        text,
                        'html'
                    )
                end
            end
        end
    end
    return true
end

return githubfeed