--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local translate = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function translate:init(configuration)
    translate.arguments = 'translate <language> <text>'
    translate.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('translate'):command('tl').table
    translate.help = configuration.command_prefix .. 'translate <language> <text> - Translates input into the given language (if arguments are given), else the replied-to message is translated into ' .. self.info.first_name .. '\'s language. Alias: ' .. configuration.command_prefix .. 'tl.'
end

function translate:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local lang
    if not mattata.get_word(input) or mattata.get_word(input):len() > 2 then
        lang = language.locale
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

function translate:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        if not message.reply_to_message then
            return mattata.send_reply(
                message,
                translate.help
            )
        end
        local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(message.reply_to_message.text))
        if res ~= 200 then
            return mattata.send_reply(
                message,
                language.errors.connection
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
        lang = language.locale
    else
        lang = mattata.get_word(input)
    end
    local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. lang .. '&text=' .. url.escape(input:gsub(lang .. ' ', '')))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
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