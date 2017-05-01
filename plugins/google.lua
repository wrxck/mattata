--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local google = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function google:init()
    google.commands = mattata.commands(self.info.username)
    :command('google')
    :command('g').table
    google.help = '/google <query> - Searches Google for the given search query and returns the most relevant result(s). Alias: /g.'
end

function google:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input
    then
        return
    end
    local jstr, res = https.request(
        string.format(
            'https://www.googleapis.com/customsearch/v1/?key=%s&cx=%s&gl=en&fields=items%%28title,link%%29&q=%s',
            configuration.keys.google.api_key,
            configuration.keys.google.cse_key,
            url.escape(input)
        )
    )
    if res ~= 200
    then
        return
    end
    local jdat = json.decode(jstr)
    if not jdat.items
    then
        return
    end
    local results = {}
    local id = 0
    for _, v in ipairs(jdat.items)
    do
        id = id + 1
        table.insert(
            results,
            mattata.inline_result()
            :id(id)
            :type('article')
            :title(v.title)
            :url(v.link)
            :input_message_content(
                mattata.input_text_message_content(
                    string.format(
                        '<a href="%s">%s</a>',
                        mattata.escape_html(v.link),
                        mattata.escape_html(v.title)
                    ),
                    'html'
                )
            )
        )
    end
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function google:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            google.help
        )
    end
    local amount = message.chat.type == 'private'
    and 8
    or 4
    local jstr, res = https.request(
        string.format(
            'https://www.googleapis.com/customsearch/v1/?key=%s&cx=%s&gl=en&fields=items%%28title,link%%29&q=%s',
            configuration.keys.google.api_key,
            configuration.keys.google.cse_key,
            url.escape(input)
        )
    )
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.items
    then
        return mattata.send_reply(
            message,
            language['errors']['results']
        )
    end
    local results = {}
    for _, v in ipairs(jdat.items)
    do
        table.insert(
            results,
            string.format(
                '• <a href="%s">%s</a>',
                mattata.escape_html(v.link),
                mattata.escape_html(v.title)
            )
        )
    end
    return mattata.send_message(
        message.chat.id,
        table.concat(
            results,
            '\n'
        ),
        'html'
    )
end

return google