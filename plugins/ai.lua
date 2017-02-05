--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local ai = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local cleverbot = require('mattata-ai')

function ai:on_inline_query(inline_query, configuration, language)
    local input = inline_query.query
    local output = cleverbot.talk(input, 1)
    if not output then
        output = 'I don\'t feel like talking at the moment'
    elseif language.locale ~= 'en' then
        local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(output))
        if res == 200 then
            local jdat = json.decode(jstr)
            output = jdat.text[1]
        else
            return false
        end
    end
    local results = json.encode(
        {
            {
                ['type'] = 'article',
                ['id'] = '1',
                ['title'] = 'mattata: ' .. output,
                ['description'] = 'You: ' .. input,
                ['input_message_content'] = {
                    ['message_text'] = '<b>Me:</b> ' .. mattata.escape_html(input) .. '\n<b>mattata:</b> ' .. mattata.escape_html(output),
                    ['parse_mode'] = 'html'
                }
            }
        }
    )
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function ai:on_message(message, configuration, language, ai_type)
    mattata.send_chat_action(message.chat.id, 'typing')
    local output = cleverbot.talk(message.text, ai_type)
    if not output then
        message.from.first_name = message.from.first_name:gsub('%%', '%%%%')
        return mattata.send_reply(
            message,
            language.ai['57']:gsub('NAME', message.from.first_name),
            nil
        )
    end
    local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language.locale .. '&text=' .. url.escape(output))
    if res == 200 then
        local jdat = json.decode(jstr)
        output = jdat.text[1]
    end
    return mattata.send_reply(
        message,
        output
    )
end

return ai