--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See ./LICENSE for details.
]]

local wikipedia = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function wikipedia:init()
    wikipedia.commands = mattata.commands(
        self.info.username
    ):command('wikipedia')
     :command('wiki')
     :command('w').table
    wikipedia.help = [[/wikipedia <query> - Searches Wikipedia for the given search query and returns the most relevant article. Aliases: /wiki, /w.]]
end

function wikipedia:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            wikipedia.help
        )
    end
    local jstr, res = https.request('https://en.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.query.searchinfo.totalhits == 0 then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local title
    for _, v in ipairs(jdat.query.search) do
        if not v.snippet:match('may refer to:') then
            title = v.title
            break
        end
    end
    if not title then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local res_jstr, res_code = https.request('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exchars=4000&explaintext=&titles=' .. url.escape(title))
    if res_code ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local _, text = next(json.decode(res_jstr).query.pages)
    if not text then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    text = text.extract
    local l = text:find('\n')
    if l then
        text = text:sub(1, l - 1)
    end
    local final_url = 'https://en.wikipedia.org/wiki/' .. url.escape(title)
    title = mattata.escape_html(title)
    local short_title = title:gsub('%(.+%)', '')
    local combined_text, count = text:gsub('^' .. short_title, '<b>' .. short_title .. '</b>')
    local output
    if count == 1 then
        output = combined_text
    else
        output = '<b>' .. title .. '</b>\n' .. text
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '%s\n<a href="%s">Read more.</a>',
            output,
            mattata.escape_html(final_url)
        ),
        'html'
    )
end

return wikipedia