--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local ai = {}

local mattata = require('mattata')
local cleverbot = require('mattata-ai')

function ai:on_message(message, configuration, language)
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local output = cleverbot.talk(message.text)
    if not output then
        return mattata.send_reply(
            message,
            'I don\'t feel like talking right now.'
        )
    end
    return mattata.send_reply(
        message,
        output
    )
end

return ai