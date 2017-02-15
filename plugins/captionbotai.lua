--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local captionbotai = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local configuration = require('configuration')

function captionbotai.conversation()
    local str, res = https.request('https://www.captionbot.ai/api/init')
    if res ~= 200 then
        return false
    end
    return str:match('%"(.-)%"') or str
end

function captionbotai.request(input, id)
    local body = string.format(
        '{"conversationId":"%s","waterMark":"","userMessage":"%s"}',
        id,
        input
    )
    local response = {}
    local _, code = https.request(
        {
            ['url'] = 'https://www.captionbot.ai/api/message',
            ['method'] = 'POST',
            ['headers'] = {
                ['Accept'] = '*/*',
                ['Accept-Encoding'] = 'gzip, deflate, br',
                ['Accept-Language'] = 'en-US,en;q=0.8',
                ['Connection'] = 'keep-alive',
                ['Content-Length'] = body:len(),
                ['Content-Type'] = 'application/json; charset=UTF-8',
                ['Host'] = 'www.captionbot.ai',
                ['Origin'] = 'https://www.captionbot.ai',
                ['Referer'] = 'https://www.captionbot.ai/',
                ['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36',
                ['X-Requested-With'] = 'XMLHttpRequest'
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if code ~= 200 then
        return false
    end
    local jstr, res = https.request('https://www.captionbot.ai/api/message?waterMark=&conversationId=' .. url.escape(id))
    jstr = jstr:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"'):gsub(configuration.bot_token, '')
    print(jstr)
    local jdat = json.decode(jstr)
    return jdat.BotMessages[2]:gsub('\\n', ' ')
end

function captionbotai:on_message(message, configuration)
    local file = mattata.get_file(message.photo[#message.photo].file_id) -- Gets the highest resolution available for the best result.
    if not file then
        return
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local init = captionbotai.conversation()
    if not init then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local output = captionbotai.request(
        string.format(
            'https://api.telegram.org/file/bot%s/%s',
            configuration.bot_token,
            file.result.file_path
        ),
        init
    )
    if not output or output:lower():match('^https%:%/%/') then
        return mattata.send_reply(
            message,
            'I really cannot describe that picture 😳'
        )
    end
    output = output:match('%, but (.-)$') or output
    return mattata.send_reply(
        message,
        output:gsub('%.$', '')
    )
end

return captionbotai