package.path = '/usr/local/share/lua/5.3/?.lua;/usr/local/share/lua/5.3/?/init.lua;/usr/local/lib/lua/5.3/?.lua;/usr/local/lib/lua/5.3/?/init.lua;../?.lua;./?/init.lua'
local redis = require('libs.redis')
local configuration = require('configuration')
local api = require('telegram-bot-lua.core').configure(configuration.bot_token)
local tools = require('telegram-bot-lua.tools')
local https = require('ssl.https')
local json = require('dkjson')
local ltn12 = require('ltn12')

while true do
    local messages = redis:keys('transcribe:*:*')
    if next(messages) then
        for _, msg in pairs(messages) do
            local message = json.decode(redis:get(msg))
            local voice = message.voice
            local file = api.get_file(voice.file_id)
            if file then
                local file_name = file.result.file_path
                local file_path = string.format('https://api.telegram.org/file/bot%s/%s', configuration.bot_token, file_name)
                tools.download_file(file_path, voice.file_id .. '.oga', configuration.bot_directory .. '/')
                os.execute('ffmpeg -i ' .. configuration.bot_directory .. '/' .. voice.file_id .. '.oga -ac 1 -y ' .. configuration.bot_directory .. '/' .. voice.file_id .. '.mp3')
                os.remove(configuration.bot_directory .. '/' .. voice.file_id .. '.oga')
                file = io.open(configuration.bot_directory .. '/' .. voice.file_id .. '.mp3', 'r')
                local current = file:seek()
                local size = file:seek('end')
                file:seek('set', current)
                size = tonumber(size)
                os.remove(configuration.bot_directory .. '/' .. voice.file_id .. '.mp3')
                local response = {}
                local _, res = https.request({
                ['url'] = 'https://api.wit.ai/speech',
                ['method'] = 'POST',
                ['headers'] = {
                    ['Authorization'] = 'Bearer ' .. configuration.keys.transcribe,
                    ['Content-Type'] = 'audio/mpeg3',
                    ['Content-Length'] = size
                },
                ['redirect'] = false,
                ['source'] = ltn12.source.file(file),
                ['sink'] = ltn12.sink.table(response)
                })
                if res == 200 then
                    local jstr = table.concat(response)
                    local jdat = json.decode(jstr)
                    if jdat then
                        local nothing = {
                            '*bong noises*',
                            '*tumbleweed passes*',
                            '*silent noises*',
                            '*unknown sounds*'
                        }
                        local text = jdat.text or jdat._text or false
                        local output = '<pre>Transcription ' .. tools.symbols.next .. ' ' .. nothing[math.random(#nothing)] .. '</pre>'
                        if text and text ~= '' then
                            output = '<pre>Transcription ' .. tools.symbols.next .. ' ' .. tools.escape_html(text) .. '</pre>'
                        end
                        local ids = {
                            'CQACAgQAAx0CVClmWQACHZFe-9jPBIqWiyNMnkLTBsogIZGFeQACIQcAAvNJ2VOZvtK5bU4CSBoE',
                            'CQACAgQAAx0CVClmWQACHZZe-9og8tRI6K4ZjQaxpMxAva5gjQACIgcAAvNJ2VNwy64JjeDiwRoE'
                        }
                        if math.random(2) == 2 and (not text or text == '') then
                            if math.random(3) == 1 then
                                api.send_voice(message.chat.id, 'AwACAgEAAx0CSdNVGgABBus7XvvbfQNDreQ-ZFMedF8xYDagcjsAAt4AAx7N4UfVVxLVLBpPZxoE')
                            else
                                api.send_audio(message.chat.id, ids[math.random(#ids)], nil, nil, nil, nil, nil, false, message.message_id)
                            end
                        else
                            api.send_reply(message, output, 'html')
                        end
                        redis:del(msg)
                    else
                        error('No jdat object!')
                    end
                else
                    print('Connection error!', '[' .. res .. ']')
                end
            else
                error('No file!')
            end
            redis:del(msg)
        end
    end
    os.execute('sleep 1.5s')
end