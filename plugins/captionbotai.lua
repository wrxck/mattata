--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local captionbotai = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local configuration = require('configuration')

function captionbotai.get_conversation_id()
    local str, res = https.request('https://www.captionbot.ai/api/init')
    if res ~= 200 then
        return false
    end
    if not str:match('%"(.-)%"') then
        return false
    end
    return str:match('%"(.-)%"')
end

function captionbotai.make_request(input, id)
    local body = '{"conversationId":"' .. id .. '","waterMark":"","userMessage":"' .. input .. '"}'
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
    jstr = jstr:gsub(configuration.bot_token, ''):gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"'):gsub('"' .. input .. '",', '')
    local jdat = json.decode(jstr)
    return jdat.BotMessages[2]
end

function captionbotai:on_photo_receive(message, configuration, language)
    local file = mattata.get_file(message.photo[1].file_id)
    if not file then
        return
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local init = captionbotai.get_conversation_id()
    if not init then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local output = captionbotai.make_request('https://api.telegram.org/file/bot' .. configuration.bot_token .. '/' .. file.result.file_path, init)
    if not output then
        return mattata.send_reply(
            message,
            'I really can\'t describe the picture 😳'
        )
    end
    return mattata.send_reply(
        message,
        output
    )
end

return captionbotai