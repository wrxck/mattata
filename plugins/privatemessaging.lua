local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')

local privatemessaging = {}

function privatemessaging:init(configuration)
    privatemessaging.triggers = {
        '^' .. 'mattata ' .. '',
        '^' .. 'mattata, ' .. '',
    }
    privatemessaging.url = configuration.messaging.url
    privatemessaging.error = false
end

function privatemessaging:action(msg, configuration)
    if msg.chat.type == 'supergroup' then
        telegram_api.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' })
    end
    local input = msg.text_lower:gsub('mattata', ''):gsub('mattata,','')
    local jstr, code = HTTPS.request(privatemessaging.url .. URL.escape(input))
    local data = JSON.decode(jstr)
    if msg.chat.type == 'supergroup' then
        functions.send_reply(self, msg, data.clever)
        return
    end
end
return privatemessaging