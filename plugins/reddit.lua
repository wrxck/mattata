--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local reddit = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function reddit:init()
    reddit.commands = mattata.commands(self.info.username, { '^/r/' }):command('r/'):command('reddit').table
    reddit.help = '/r/subreddit - Returns the latest posts from the given subreddit.'
end

function reddit.format_results(posts, limit)
    local output = {}
    if #posts == 0 then
        return false
    end
    local count = 0
    for _, v in pairs(posts) do
        count = count + 1
        if count > limit then
            break
        end
        local post = v.data
        local title = post.title
        if title:len() > 250 then
            title = mattata.trim(title:sub(1, 250)) .. '...'
        end
        local short_url = 'redd.it/' .. post.id
        local result = '<a href="' .. mattata.escape_html(short_url) .. '">' .. mattata.escape_html(title) .. '</a>'
        if post.domain and not post.is_self then
            post.url = mattata.escape_html(post.url)
            post.domain = mattata.escape_html(post.domain)
            result = mattata.symbols.bullet .. ' <code>[</code><a href="' .. post.url .. '">' .. post.domain .. '</a><code>]</code> ' .. result
        else
            result = mattata.symbols.bullet .. ' ' .. result
        end
        table.insert(output, result)
    end
    return table.concat(output, '\n')
end

function reddit.on_message(_, message, configuration, language)
    local limit = message.chat.type ~= 'private' and configuration.limits.reddit.public or configuration.limits.reddit.private
    local input = mattata.input(message.text)
    local subreddit = message.text:match('^/r/([%w][%w_]+)%s?')
    if input and not subreddit then
        subreddit = input
    elseif not input and not subreddit then
        return mattata.send_reply(message, reddit.help)
    end
    if not subreddit or subreddit:len() > 21 or subreddit:len() < 2 then
        return mattata.send_reply(message, 'That\'s not a valid subreddit!')
    end
    local request_url = 'https://www.reddit.com/.json?limit=' .. limit
    local old_timeout = https.TIMEOUT
    https.TIMEOUT = 1
    if subreddit == 'random' or subreddit == 'randnsfw' then
        if message.chat.type ~= 'private' and subreddit == 'randnsfw' then
            subreddit = 'random'
        end
        local _, _, headers = https.request({
            ['url'] = 'https://www.reddit.com/r/' .. subreddit .. '.json?limit=1',
            ['redirect'] = false
        })
        subreddit = headers.location and headers.location:match('r/(.-)/%.json') or 'all'
    end
    if subreddit ~= 'all' then
        request_url = 'https://www.reddit.com/r/' .. subreddit .. '/.json?limit=' .. limit
    end
    local output = '<b>/r/' .. subreddit .. '</b>\n'
    local jstr, res = https.request(request_url)
    https.TIMEOUT = old_timeout
    if res == 404 or res == 'wantread' then
        return mattata.send_reply(message, language['errors']['results'])
    elseif res ~= 200 then
        return mattata.send_reply(message, language['errors']['connection'])
    end
    local jdat = json.decode(jstr)
    if not jdat or not jdat.data or #jdat.data.children < 1 then
        return mattata.send_reply(message, language['errors']['results'])
    end
    output = output .. reddit.format_results(jdat.data.children, limit)
    return mattata.send_message(message.chat.id, output, 'html', true)
end

return reddit