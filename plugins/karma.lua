--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local karma = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function karma.on_new_message(_, message)
    if message.chat.type == 'private' or not message.reply or (message.text ~= '+1' and message.text ~= '-1') or message.from.id == message.reply.from.id or message.reply.from.is_bot then
        return false
    end
    local risen = false
    if message.text == '+1' then
        risen = true
        redis:hincrby('user:' .. message.reply.from.id .. ':info', 'karma', 1)
    else
        redis:hincrby('user:' .. message.reply.from.id .. ':info', 'karma', -1)
    end
    local current = redis:hget('user:' .. message.reply.from.id .. ':info', 'karma')
    local user = mattata.get_formatted_user(message.reply.from.id, message.reply.from.first_name, 'html')
    local output = string.format('%s\'s karma has %s to %s.', user, risen and 'risen' or 'fallen', current)
    return mattata.send_message(message.chat.id, output, 'html')
end

return karma