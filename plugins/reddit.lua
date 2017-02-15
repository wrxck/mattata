--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local reddit = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function reddit:init()
    reddit.commands = mattata.commands(
        self.info.username,
        {
            '^/r/'
        }
    ):command('reddit')
     :command('r')
     :command('r/').table
    reddit.help = [[/reddit <subreddit/query> - Returns the latest posts from the given subreddit, or for the given query. Aliases: /r, /r/subreddit.]]
end

function reddit.format_results(posts)
    local output = ''
    for _, v in ipairs(posts) do
        local post = v.data
        local title = post.title:gsub('%[', '('):gsub('%]', ')'):gsub('&amp;', '&')
        if title:len() > 250 then
            title = title:sub(1, 250)
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

function reddit:on_message(message, configuration)
    local limit = 4
    if message.chat.type == 'private' then
        limit = 8
    end
    local text = message.text:lower()
    if text:match('^/r/.') then
        text = message.text:lower():gsub('^%/r%/', '/r r/')
    end
    local input = mattata.input(text)
    local source, url
    if input then
        if not string.match(input, '/random') then
            if input:match('^r/.') then
                input = mattata.get_word(input)
                url = 'https://www.reddit.com/%s/.json?limit='
                url = url:format(input) .. limit
                source = '*/' .. mattata.escape_markdown(input):gsub('\\', '') .. '*\n'
            else
                input = mattata.input(message.text)
                source = '*Results for* ' .. mattata.escape_markdown(input) .. '*:*\n'
                input = url.escape(input)
                url = 'https://www.reddit.com/search.json?q=%s&limit='
                url = url:format(input) .. limit
            end
        else
            return mattata.send_reply(
                message,
                configuration.errors.results
            )
        end
    else
        url = 'https://www.reddit.com/.json?limit=' .. limit
        source = '*/r/all*\n'
    end
    local jstr, res = https.request(url)
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if #jdat.data.children == 0 then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        source .. reddit.format_results(jdat.data.children),
        'markdown'
    )
end

return reddit