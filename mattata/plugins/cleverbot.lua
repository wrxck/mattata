local HTTP = require('socket.http')
local JSON = require('dkjson')
local utilities = require('mattata.utilities')
local bindings = require('mattata.bindings')

local mattata = {}

function mattata:init(config)
    mattata.name = '^' .. self.info.first_name:lower() .. ', '
    mattata.username = '^@' .. self.info.username:lower() .. ', '
    mattata.triggers = {
        '^' .. self.info.first_name:lower() .. ', ',
        '^@' .. self.info.username:lower() .. ', '
    }
    mattata.error = false
end

function mattata:action(msg, config)
    bindings.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' })
    local input = msg.text_lower:gsub(mattata.name, ''):gsub(mattata.name, '')
    local jstr, code = HTTP.request("https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text="..input..)
    local jdat = JSON.decode(jstr)
    utilities.send_message(self, msg.chat.id, jdat.mattata)
end

return mattata
