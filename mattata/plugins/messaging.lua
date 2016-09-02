local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('mattata.functions')
local telegram_api = require('mattata.telegram_api')
local messaging = {}
function messaging:init(configuration)
    messaging.triggers = {
        '^' .. 'mattata ' .. '',
        '^' .. 'mattata, ' .. '',
        '^' .. '' .. ''
    }
    messaging.url = configuration.messaging.url
end
function messaging:action(msg, configuration)
    if msg.chat.type == 'private' then
        telegram_api.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' })
    end
    local input = msg.text_lower
    local log_messaging = string.format(
        '🔔 New message! \n 👤 Username: %s [%s]\n ✉ Message: %s',
        msg.from.username and '@' .. msg.from.username or functions.build_name(
            msg.from.first_name,
            msg.from.last_name
        ),
        msg.from.id,
        input
    )
    local jstr, code = HTTPS.request(messaging.url .. URL.escape(input)):gsub('mattata', '')
    local data = JSON.decode(jstr)
    if msg.chat.type == 'private' then
        functions.send_message(self, msg.chat.id, data.clever)
        functions.send_message(self, configuration.log_chat, log_messaging)
    end
end
return messaging