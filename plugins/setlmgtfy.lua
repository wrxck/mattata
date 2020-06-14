--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setlmgtfy = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function setlmgtfy:init()
    setlmgtfy.commands = mattata.commands(self.info.username):command('setlmgtfy'):command('sl').table
    setlmgtfy.help = '/setlmgtfy <response text> - Sets the response text for the LMGTFY plugin. Alias: /sl.'
end

function setlmgtfy:on_message(message)
    if not mattata.is_group_admin(message.chat.id, message.from.id) or message.chat.type == 'private' then
        return false
    end
    local input = mattata.input(message.text)
    if not input or input:len() > 128 then
        return mattata.send_reply(message, 'Please specify some text to reply to the user with. No longer than 128 characters please!')
    end
    redis:set('chat:' .. message.chat.id .. ':lmgtfy', input)
    return mattata.send_reply(message, 'Successfully set that text as the LMGTFY response!')
end

return setlmgtfy