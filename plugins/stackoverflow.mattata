--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local stackoverflow = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local ltn12 = require('ltn12')
local zlib = require('zlib')
local html = require('htmlEntities')

function stackoverflow:init()
    stackoverflow.commands = mattata.commands(self.info.username):command('stackoverflow'):command('so').table
    stackoverflow.help = '/stackoverflow [query] - Returns the first result for the given search query on Stack Overflow. Query can be given by replying to the message you want to search or specifying it as a parameter. Alias: /so.'
    stackoverflow.url = 'https://api.stackexchange.com/2.2/search/advanced?'
end

function stackoverflow.on_message(_, message, configuration, language)
    local input = message.reply and message.reply.text or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, stackoverflow.help)
    elseif message.reply then
        message.message_id = message.reply.message_id
    end
    local query = 'order=desc&sort=relevance&site=stackoverflow&q=' .. url.escape(input)
    local response = {}
    local _, res = https.request({
        ['url'] = stackoverflow.url .. query,
        ['method'] = 'GET',
        ['headers'] = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = query:len(),
            ['Accept-Encoding'] = 'gzip'
        },
        ['source'] = ltn12.source.string(input),
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jstr = table.concat(response)
    jstr = zlib.decompress(jstr, 31)
    local jdat = json.decode(jstr)
    if not jdat.items or not jdat.items[1] then
        return mattata.send_reply(message, language.errors.results)
    end
    local limit = message.chat.type == 'private' and configuration.limits.stackoverflow.private or configuration.limits.stackoverflow.public
    local results = { '<b>Results for:</b> <em>' .. mattata.escape_html(input) .. '</em>' }
    local count = 0
    for i = 1, limit do
        if i > #jdat.items then
            break
        end
        local result = string.format('%s <a href="%s">%s</a>', mattata.symbols.bullet, jdat.items[i].link, mattata.escape_html(html.decode(jdat.items[i].title)))
        table.insert(results, result)
        count = count + 1
    end
    local output = table.concat(results, '\n')
    return mattata.send_reply(message, output, 'html', true)
end

return stackoverflow