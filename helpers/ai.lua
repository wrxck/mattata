local ai = {}
package.path = '/usr/local/share/lua/5.3/?.lua;/usr/local/share/lua/5.3/?/init.lua;/usr/local/lib/lua/5.3/?.lua;/usr/local/lib/lua/5.3/?/init.lua;../?.lua;./?/init.lua'
local redis = require('libs.redis')
local configuration = require('configuration')
local api = require('telegram-bot-lua.core').configure(configuration.bot_token)
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local ltn12 = require('ltn12')
local md5 = require('md5')

function ai.unescape(str)
    if not str then
        return false
    end
    str = str:gsub('%%(%x%x)', function(x)
        return tostring(tonumber(x, 16)):char()
    end)
    return str
end

function ai.cookie()
    local cookie = {}
    local _, res, headers = https.request({
        ['url'] = 'http://www.cleverbot.com/',
        ['method'] = 'GET'
    })
    if res ~= 200 then
        return false
    end
    local set = headers['set-cookie']
    local k, v = set:match('([^%s;=]+)=?([^%s;]*)')
    cookie[k] = v
    return cookie
end

function ai.talk(message, reply, language)
    if not message then
        return false
    end
    return ai.cleverbot(message, reply, language)
end

function ai.cleverbot(message, reply, language)
    local cookie = ai.cookie()
    if not cookie then
        return false
    end
    for k, v in pairs(cookie) do
        cookie[#cookie + 1] = k .. '=' .. v
    end
    local query = 'stimulus=' .. url.escape(message)
    if reply then
        query = query .. '&vText2=' .. url.escape(reply)
    end
    query = query .. '&cb_settings_language=' .. language .. '&cb_settings_scripting=no&islearning=1&icognoid=wsf&icognocheck='
    local icognocheck = md5.sumhexa(query:sub(8, 33))
    query = query .. icognocheck
    local agents = {
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36',
        'Mozilla/5.0 CK={} (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko',
        'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/18.17763'
    }
    local agent = agents[math.random(#agents)]
    local old_timeout = https.TIMEOUT
    https.TIMEOUT = 5
    local _, res, headers = https.request({
        ['url'] = 'https://www.cleverbot.com/webservicemin?uc=UseOfficialCleverbotAPI&dl=en&flag=&user=&mode=1&alt=0&reac=&emo=&sou=website&xed=&dl=' .. language .. '&',
        ['method'] = 'POST',
        ['headers'] = {
            ['Host'] = 'www.cleverbot.com',
            ['User-Agent'] = agent,
            ['Accept'] = '*/*',
            ['Accept-Language'] = 'en-US,en;q=0.5',
            ['Accept-Encoding'] = 'gzip, deflate',
            ['Referrer'] = 'https://www.cleverbot.com/',
            ['Content-Length'] = query:len(),
            ['Content-Type'] = 'text/plain;charset=UTF-8',
            ['Cookie'] = table.concat(cookie, ';'),
            ['DNT'] = '1'
        },
        ['source'] = ltn12.source.string(query)
    })
    https.TIMEOUT = old_timeout
    if res ~= 200 or not headers.cboutput then
        return false
    end
    local output = ai.unescape(headers.cboutput)
    if not output then
        return false
    end
    return output
end

function ai.process(message, reply, language)
    if not message then
        return ai.unsure()
    end
    local original_message = message
    message = message:lower()
    local success = api.get_me()
    if message:match('^hi%s*') or message:match('^hello%s*') or message:match('^howdy%s*') or message:match('^hi.?$') or message:match('^hello.?$') or message:match('^howdy.?$') then
        return ai.greeting()
    elseif message:match('^bye%s*') or message:match('^good[%-%s]?bye%s*') or message:match('^bye$') or message:match('^good[%-%s]?bye$') then
        return ai.farewell()
    elseif message:match('%s*y?o?ur%s*name%s*') or message:match('^what%s*is%s*y?o?ur%s*name') then
        return string.format('My name is %s, what\'s yours?', success.result.first_name)
    elseif message:match('^do y?o?u[%s.]*') then
        return ai.choice(message)
    elseif message:match('^how%s*a?re?%s*y?o?u.?') or message:match('.?how%s*a?re?%s*y?o?u%s*') or message:match('.?how%s*a?re?%s*y?o?u.?$') or message:match('^a?re?%s*y?o?u%s*oka?y?.?$') or message:match('%s*a?re?%s*y?o?u%s*oka?y?.?$') then
        return ai.feeling()
    else
        return ai.talk(original_message, reply or false, language)
    end
end

function ai.greeting()
    local greetings = {
        'Hello!',
        'Hi.',
        'How are you?',
        'What\'s up?',
        'Are you okay?',
        'How\'s it going?',
        'What\'s your name?',
        'What are you up to?',
        'Hello.',
        'Hey!',
        'Hey.',
        'Howdy!',
        'Howdy.',
        'Hello there!',
        'Hello there.'
    }
    return greetings[math.random(#greetings)]
end

function ai.farewell()
    local farewells = {
        'Goodbye!',
        'Bye.',
        'I\'ll speak to you later, yeah?',
        'See ya!',
        'Oh, bye then.',
        'Bye bye.',
        'BUH-BYE!',
        'Aw. See ya.'
    }
    return farewells[math.random(#farewells)]
end

function ai.unsure()
    local unsure = {
        'What?',
        'I really don\'t understand.',
        'What are you trying to say?',
        'Huh?',
        'Um..?',
        'Excuse me?',
        'What does that mean?'
    }
    return unsure[math.random(#unsure)]
end

function ai.feeling()
    local feelings = {
        'I am good thank you!',
        'I am well.',
        'Good, how about you?',
        'Very well thank you; you?',
        'Never better!',
        'I feel great!'
    }
    return feelings[math.random(#feelings)]
end

function ai.choice(message)
    local generic_choices = {
        'I do!',
        'I do not.',
        'Nah, of course not!',
        'Why would I?',
        'Um...',
        'I sure do!',
        'Yes, do you?',
        'Nope!',
        'Yeah!'
    }
    local personal_choices = {
        'I love you!',
        'I\'m sorry, but I don\'t really like you!',
        'I really like you.',
        'I\'m crazy about you!'
    }
    if message:match('%s*me.?$') then
        return personal_choices[math.random(#personal_choices)]
    end
    return generic_choices[math.random(#generic_choices)]
end

function ai.offline()
    local responses = {
        'I don\'t feel like talking right now!',
        'I don\'t want to talk at the moment.',
        'Can we talk later?',
        'I\'m not in the mood right now...',
        'Leave me alone!',
        'Please can I have some time to myself?',
        'I really don\'t want to talk to anyone right now!',
        'Please leave me in peace.',
        'I don\'t wanna talk right now, I hope you understand.'
    }
    return responses[math.random(#responses)]
end

while true do
    local messages = redis:keys('ai:*:*')
    if next(messages) then
        for _, message in pairs(messages) do
            local chat_id, message_id = message:match('^ai:(.-):(.-)$')
            local text = redis:hget(message, 'text')
            local reply = redis:hget(message, 'reply') or false
            local language = redis:hget(message, 'language') or 'en'
            api.send_chat_action(chat_id, 'typing')
            local output = ai.process(text, reply, language)
            if output then
                local msg = {
                    ['chat'] = {
                        ['id'] = chat_id
                    },
                    ['message_id'] = message_id
                }
                redis:del(message)
                local jstr, res = https.request('https://translate.yandex.net/api/v1.5/tr.json/translate?key=' .. configuration.keys.translate .. '&lang=' .. language .. '&text=' .. url.escape(output))
                if res ~= 200 then
                    return api.send_reply(msg, output)
                end
                local jdat = json.decode(jstr)
                if not jdat.text then
                    return api.send_reply(msg, output)
                else
                    api.send_reply(msg, jdat.text[1])
                end
            end
        end
    end
    os.execute('sleep 0.1s')
end