--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local dictionary = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

function dictionary:init(configuration)
    dictionary.commands = mattata.commands(self.info.username):command('dictionary'):command('define').table
    dictionary.help = '/dictionary <word> - Looks up the given word in the Oxford Dictionary and returns the relevant definition(s). Alias: /define.'
    dictionary.url = 'https://od-api.oxforddictionaries.com/api/v1/entries/en/'
    dictionary.id = configuration.keys.dictionary.id
    dictionary.key = configuration.keys.dictionary.key
end

function dictionary.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, dictionary.help)
    end
    local body = {}
    local _, res = https.request({
        ['url'] = dictionary.url .. url.escape(input),
        ['headers'] = {
            ['app_id'] = dictionary.id,
            ['app_key'] = dictionary.key
        },
        ['sink'] = ltn12.sink.table(body),
    })
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    body = table.concat(body)
    local jdat = json.decode(body)
    if not jdat or not jdat.results[1] or not jdat.results[1].word or not jdat.results[1].lexicalEntries then
        return mattata.send_reply(message, language.errors.results)
    end
    local word = jdat.results[1].word
    word = mattata.escape_html(word)
    local results = #jdat.results[1].lexicalEntries
    results = tonumber(results) > 4 and 4 or results
    local definitions = {}
    for i = 1, results do
        if jdat.results[1] and jdat.results[1].lexicalEntries and jdat.results[1].lexicalEntries[i].entries and jdat.results[1].lexicalEntries[i].entries[1].senses and jdat.results[1].lexicalEntries[i].entries[1].senses[1].definitions then
            local entry = jdat.results[1].lexicalEntries[i].entries[1].senses[1].definitions[1]
            entry = entry:gsub(':$', ''):gsub('%.$', '')
            entry = mattata.escape_html(entry)
            table.insert(definitions, '• ' .. entry)
        end
    end
    local output = '<b>' .. word .. '</b>\n\n' .. table.concat(definitions, '\n')
    return mattata.send_message(message.chat.id, output, 'html')
end

return dictionary