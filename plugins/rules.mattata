--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local rules = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function rules:init()
    rules.commands = mattata.commands(self.info.username):command('rules').table
    rules.help = '/rules - View the group\'s rules.'
end

function rules:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return false
    end
    local output = mattata.get_value(
        message.chat.id,
        'rules'
    )
    or 'There are no rules set for this chat!'
    if mattata.get_setting(
        message.chat.id,
        'send rules in group'
    )
    then
        return mattata.send_message(
            message.chat.id,
            output
        )
    end
    local success = mattata.send_message(
        message.from.id,
        output,
        'markdown',
        true,
        false
    )
    return mattata.send_reply(
        message,
        success
        and 'I have sent you the rules via private chat!'
        or 'You need to speak to me in private chat before I can send you the rules! Just click [here](https://t.me/' .. self.info.username .. '), press the "START" button, and try again!',
        'markdown'
    )
end

return rules