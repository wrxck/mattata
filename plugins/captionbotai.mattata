--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local captionbotai = {}
local mattata = require('mattata')
local https = require('ssl.https')
local ltn12 = require('ltn12')

function captionbotai:on_new_message(message, configuration, language)
    if message.photo or (message.reply and message.reply.photo) then
        if message.text:lower():match('^wh?at .- th[ia][st].-') or message.text:lower():match('^who .- th[ia][st].-') then
            return captionbotai.on_message(self, message, configuration, language)
        end
    end
end

function captionbotai.request(input, configuration)
    local body = string.format('{Type: "CaptionRequest", Content: "%s"}', input)
    local sink, response = ltn12.sink.table()
    local _, res = https.request(
        {
            ['url'] = 'http://captionbot.azurewebsites.net/api/messages',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Length'] = body:len(),
                ['Content-Type'] = 'application/json',
                ['DNT'] = 1,
                ['Host'] = 'captionbot.azurewebsites.net',
                ['Origin'] = 'https://www.captionbot.ai',
                ['Referer'] = 'https://www.captionbot.ai/',
                ['User-Agent'] = 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.138 Mobile Safari/537.36'
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = sink
        }
    )
    response = table.concat(response)
    if res ~= 200 then
        return false
    end
    response = response:gsub('^"', ''):gsub('"$', ''):gsub('\\"', '"'):gsub(configuration.bot_token, '')
    return response
end

function captionbotai.on_message(_, message, configuration, language)
    if message.reply and message.reply.photo then
        message.photo = message.reply.photo
    end
    local file = mattata.get_file(message.photo[#message.photo].file_id) -- Gets the highest resolution available, for the best result.
    if not file then
        return false
    end
    mattata.send_chat_action(message.chat.id)
    local request_url = string.format('https://api.telegram.org/file/bot%s/%s', configuration.bot_token, file.result.file_path)
    local output = captionbotai.request(request_url, configuration)
    if not output or output:lower():match('^https%:%/%/') then
        return mattata.send_reply(message, language['captionbotai']['1'] .. ' 😳')
    end
    output = output:match('%, but (.-)$') or output
    output = output:gsub('%.$', '')
    return mattata.send_reply(message, output)
end

return captionbotai