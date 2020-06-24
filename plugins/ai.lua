--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ai = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function ai:on_new_message(message)
    if not message.text or message.text:match('^[/!#]') then
        return false
    elseif redis:get('chatroulette:' .. message.from.id) then
        return false
    elseif message.text and message.reply and message.reply.text and message.reply.from.id == self.info.id and not message.reply.entities then
        return ai.on_message(self, message)
    end
    local triggers = {
        '^' .. self.info.first_name:lower() .. ',? ',
        '^@?' .. self.info.username:lower() .. ',? '
    }
    for _, trigger in pairs(triggers) do
        if message.text:lower():match(trigger) then
            return ai.on_message(self, message)
        end
    end
    if message.chat.type == 'private' and message.text then
        return ai.on_message(self, message)
    elseif math.random(30) == 30 and not message.reply then
        return ai.on_message(self, message)
    end
    return
end

function ai:on_message(message)
    self.is_ai = true
    local text = message.text:gsub('^' .. self.info.first_name:lower() .. ',? ', ''):gsub('^@?' .. self.info.username:lower() .. ',? ', '')
    text = text:gsub(self.info.first_name:lower(), 'you'):gsub('@?' .. self.info.username:lower(), 'you')
    local language = mattata.get_setting(message.chat.id, 'force group language') and 'en' or mattata.get_user_language(message.from.id):match('^(..)')
    if message.reply and message.reply.text and message.reply.from.id == self.info.id and not message.reply.entities then
        redis:hset('ai:' .. message.chat.id .. ':' .. message.message_id, 'reply', message.reply.text)
    end
    redis:hset('ai:' .. message.chat.id .. ':' .. message.message_id, 'text', text)
    redis:hset('ai:' .. message.chat.id .. ':' .. message.message_id, 'language', language)
    return
end

return ai