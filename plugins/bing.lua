--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local bing = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

function bing:init(configuration)
    assert(configuration.keys.bing, 'bing.lua requires an API key, and you haven\'t got one configured!')
    bing.commands = mattata.commands(self.info.username):command('bing').table
    bing.help = '/bing <query> - Searches Bing for the given search query and returns the top results.'
    bing.key = configuration.keys.bing
end

function bing.on_message(_, message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, bing.help)
    end
    local body = {}
    local _, res = https.request({
        ['url'] = 'https://api.cognitive.microsoft.com/bing/v7.0/search?responseFilter=Webpages&safeSearch=Off&q=' .. url.escape(input),
        ['headers'] = {
            ['Ocp-Apim-Subscription-Key'] = bing.key,
            ['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; Touch; rv:11.0) like Gecko'
        },
        ['sink'] = ltn12.sink.table(body),
    })
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(table.concat(body))
    if not jdat.webPages then
        return mattata.send_reply(message, language.errors.results)
    end
    local limit = message.chat.type == 'private' and configuration.limits.bing.private or configuration.limits.bing.public
    if limit > #jdat.webPages.value and #jdat.webPages.value or limit == 0 then
        return mattata.send_reply(message, language.errors.results)
    end
    local results = {}
    local count = 0
    for i = 1, limit do
        if jdat.webPages.value[i].snippet:len() > 100 then
            jdat.webPages.value[i].snippet = jdat.webPages.value[i].snippet:sub(1, 100) .. '...'
        end
        if count > limit - 4 then
            table.insert(results, string.format('%s <a href="%s">%s</a>', mattata.symbols.bullet, jdat.webPages.value[i].url, mattata.escape_html(jdat.webPages.value[i].name)))
        else
            table.insert(results, string.format('%s <a href="%s">%s</a> <em>%s</em>', mattata.symbols.bullet, jdat.webPages.value[i].url, mattata.escape_html(jdat.webPages.value[i].name), mattata.escape_html(jdat.webPages.value[i].snippet)))
        end
        count = count + 1
    end
    local output = table.concat(results, '\n')
    return mattata.send_message(message.chat.id, output, 'html')
end

return bing