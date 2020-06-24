--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local addtrigger = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function addtrigger:init()
    addtrigger.commands = mattata.commands(self.info.username):command('addtrigger'):command('newtrigger'):command('addcustom').table
    addtrigger.help = '/addtrigger <trigger> \\n <value> - Allows admins to add triggers, which makes the bot reply with the given value when the trigger is sent in chat. Triggers can be no longer than 32 characters long, and values can be no more than 512 characters long. Trigger values must be sent on a new line. Aliases: /newtrigger, /addcustom.'
end

function addtrigger:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local input = mattata.input(message.text)
    if not input or not input:match('^.-\n.-$') then
        return mattata.send_reply(message, addtrigger.help)
    end
    local trigger, value = input:match('^(.-)\n(.-)$')
    local count = 0
    local is_duplicate = false
    local all = redis:hgetall('triggers:' .. message.chat.id)
    for _, v in ipairs(all) do
        count = count + 1
        if v == trigger then
            is_duplicate = true
        end
    end
    if is_duplicate then
        return mattata.send_reply(message, 'That trigger already exists! To modify it, delete it first using /triggers.')
    end
    if trigger:len() > 32 then
        return mattata.send_reply(message, 'The trigger needs to be 1-32 characters long, and alpha-numerical.')
    elseif value:len() > 512 then
        return mattata.send_reply(message, 'The value must be no more than 512 characters long!')
    end
    redis:hset('triggers:' .. message.chat.id, trigger, value)
    return mattata.send_reply(message, 'Successfully added that trigger! To view all of this chat\'s triggers, send /triggers.')
end

return addtrigger