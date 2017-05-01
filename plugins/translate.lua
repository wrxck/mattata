--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local translate = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function translate:init()
    translate.commands = mattata.commands(
        self.info.username
    ):command('translate')
     :command('tl').table
    translate.help = [[/translate [locale] <text> - If a locale is given, the given text is translated into the said locale's language. If no locale is given then the given text is translated into the bot's configured language. If the command is used in reply to a message containing text, then the replied-to text is translated and the translation is returned. Alias: /tl.]]
end

function translate:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local lang
    if not mattata.get_word(input) or mattata.get_word(input):len() > 2 then
        lang = configuration.language
    else
        lang = mattata.get_word(input)
    end
    local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. lang .. '&text=' .. url.escape(input:gsub(lang .. ' ', '')))
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = jdat.text[1],
                    ['description'] = 'Click to send your translation.',
                    ['input_message_content'] = {
                        ['message_text'] = jdat.text[1]
                    }
                }
            }
        )
    )
end

function translate:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        if not message.reply then
            return mattata.send_reply(
                message,
                translate.help
            )
        end
        local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. configuration.language .. '&text=' .. url.escape(message.reply.text))
        if res ~= 200 then
            return mattata.send_reply(
                message,
                configuration.errors.connection
            )
        end
        local jdat = json.decode(jstr)
        return mattata.send_message(
            message.chat.id,
            '<b>Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '):</b>\n' .. mattata.escape_html(jdat.text[1]),
            'html'
        )
    end
    local lang
    if not mattata.get_word(input) or mattata.get_word(input):len() > 2 then
        lang = configuration.language
    else
        lang = mattata.get_word(input)
    end
    local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. lang .. '&text=' .. url.escape(input:gsub(lang .. ' ', '')))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        '<b>Translation (from ' .. jdat.lang:gsub('%-', ' to ') .. '):</b>\n' .. mattata.escape_html(jdat.text[1]),
        'html'
    )
end

return translate