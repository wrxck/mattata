--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local news = {}

local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')
local redis = require('mattata-redis')

function news:init(configuration)
    news.arguments = 'news'
    news.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('news')
     :command('nsources')
     :command('setnews').table
    news.help = '/news <source> - Sends the current top story from the given news source. Use /nsources to view a list of available sources.'
end

function news.send_sources(message)
    local input = mattata.input(message.text_lower)
    if not input then
        input = false
    else
        local success = pcall(
            function()
                return input:match(input)
            end
        )
        if not success then
            return mattata.send_reply(
                message,
                string.format(
                    '"<code>%s</code>" isn\'t a valid Lua pattern.',
                    mattata.escape_html(input)
                ),
                'html'
            )
        end
    end
    local sources = news.get_sources(input)
    if not sources then
        return mattata.send_reply(
            message,
            'I couldn\'t retrieve a list of sources.'
        )
    end
    sources = table.concat(
        sources,
        ', '
    )
    if input then
        sources = string.format(
            '<b>News sources found matching</b> "<code>%s</code>":\n\n%s',
            mattata.escape_html(input),
            sources
        )
    else
        sources = string.format(
            '<b>Here are the current available news sources you can use with</b> /news<b>. Use</b> /nsources &lt;query&gt; <b>to search the list of news sources for a more specific set of results. Searches are matched using Lua patterns</b>\n\n%s',
            sources
        )
    end
    return mattata.send_message(
        message.chat.id,
        sources,
        'html'
    )
end

function news.set_news(message)
    local input = mattata.input(message.text_lower)
    if input then
        input = input:gsub('%-', ' ')
    end
    local preferred_source = redis:get(
        string.format(
            'user:%s:news',
            message.from.id
        )
    )
    if not preferred_source and not input then
        return mattata.send_reply(
            message,
            'You don\'t have a preferred news source. Use /setnews <source> to set one. View a list of sources using /nsources, or narrow down the results by using /nsources <query>.'
        )
    elseif not input then
        return mattata.send_reply(
            message,
            'Your current preferred news source is ' .. preferred_source .. '. Use /setnews <source> to change it. View a list of sources using /nsources, or narrow down the results by using /nsources <query>.'
        )
    elseif preferred_source == input then
        return mattata.send_reply(
            message,
            'Your preferred source is already set to ' .. input .. '! Use /news to view the current top story.'
        )
    end
    if not news.is_valid(input) then
        return mattata.send_reply(
            message,
            'That\'s not a valid news source. View a list of sources using /nsources, or narrow down the results by using /nsources <query>.'
        )
    end
    redis:set(
        string.format(
            'user:%s:news',
            message.from.id
        ),
        input
    )
    return mattata.send_reply(
        message,
        'Your preferred news source has been updated to ' .. input .. '! Use /news to view the current top story.'
    )
end

function news.is_valid(source)
    local sources = news.get_sources()
    for k, v in pairs(sources) do
        if v == source then
            return true
        end
    end
    return false
end

function news.get_sources(input)
    local jstr, res = https.request('https://newsapi.org/v1/sources')
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.status ~= 'ok' then
        return false
    end
    local sources = {}
    for k, v in pairs(jdat.sources) do
        v.id = v.id:gsub('%-', ' ')
        if input then
            if v.id:match(input) then
                table.insert(
                    sources,
                    v.id
                )
            end
        else
            table.insert(
                sources,
                v.id
            )
        end
    end
    table.sort(sources)
    return sources
end

function news:on_message(message, configuration, language)
    if message.text:match('^%/nsources') then
        return news.send_sources(message)
    elseif message.text:match('^%/setnews') then
        return news.set_news(message)
    end
    local input = mattata.input(message.text_lower)
    if not input then
        local preferred_source = redis:get(
            string.format(
                'user:%s:news',
                message.from.id
            )
        )
        if preferred_source then
            input = preferred_source
        else
            return mattata.send_reply(
                message,
                news.help
            )
        end
    end
    input = input:gsub('-', ' ')
    if not news.is_valid(input) then
        return mattata.send_reply(
            message,
            'That\'s not a valid source, use /nsources to view a list of available sources. If you have a preferred source, use /setnews <source> to automatically have news from that source sent when you send /news, without any arguments needed.'
        )
    end
    input = input:gsub('%s', '-')
    local jstr, res = https.request('https://newsapi.org/v1/articles?apiKey=' .. configuration.keys.news .. '&source=' .. input .. '&sortBy=top')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.articles[1] then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    jdat.articles[1].publishedAt = jdat.articles[1].publishedAt:gsub('T.-$', '')
    local output = string.format(
        '<b>%s</b> <code>[%s]</code>\n%s\n<a href="%s">Read more.</a>',
        jdat.articles[1].title,
        mattata.escape_html(jdat.articles[1].publishedAt),
        jdat.articles[1].description,
        jdat.articles[1].url
    )
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return news