--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local statistics = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function statistics:init(configuration)
    statistics.arguments = 'statistics'
    statistics.help = '/statistics - View statistics about the chat you are in. Only the top 10, most-talkative users are listed.'
end

function statistics.get_name(user)
    if user.name then
        return user.name
    end
    local text = ''
    if user.first_name then
        text = user.first_name .. ' '
    end
    if user.last_name then
        text = text .. user.last_name
    end
    return text
end

function statistics.get_messages(id, chat)
    local info = {}
    local user = redis:hgetall('user:' .. id)
    info.messages = tonumber(redis:get('messages:' .. id .. ':' .. chat)) or 0
    info.name = statistics.get_name(user)
    return info
end

function statistics.get_statistics(chat, title, total)
    local hash = 'chat:' .. chat .. ':users'
    local users = redis:smembers(hash)
    local user_info = {}
    for i = 1, #users do
        local id = users[i]
        local user = statistics.get_messages(
            id,
            chat
        )
        table.insert(
            user_info,
            user
        )
    end
    table.sort(
        user_info,
        function(a, b)
            if a.messages and b.messages then
                return a.messages > b.messages
            end
        end
    )
    local total = 0
    for n, user in pairs(user_info) do
        local message_count = user_info[n].messages
        total = total + message_count
    end
    local text = ''
    local output = {}
    for i = 1, 10 do
        table.insert(
            output,
            user_info[i]
        )
    end
    for k, v in pairs(output) do
        local message_count = v.messages
        local percent = tostring(
            mattata.round(
                message_count / total * 100,
                1
            )
        )
        text = text .. mattata.escape_html(v.name) .. ': <b>' .. mattata.comma_value(message_count) .. '</b> [' .. percent .. '%]\n'
    end
    if text == nil or text == '' then
        return 'No messages have been sent in this chat!'
    end
    return '<b>Statistics for:</b> ' .. mattata.escape_html(title) .. '\n\n' .. text .. '\n<b>Total messages sent:</b> ' .. mattata.comma_value(total)
end

function statistics:process_message(message)
    if message.left_chat_member then
        redis:srem(
            'chat:' .. message.chat.id .. ':users',
            message.left_chat_member.id
        )
        return message
    end
    if message.from.name then
        redis:hset(
            'user:' .. message.from.id,
            'name', message.from.name
        )
    end
    if message.from.first_name then
        redis:hset(
            'user:' .. message.from.id,
            'first_name', message.from.first_name
        )
    end
    if message.from.last_name then
        redis:hset(
            'user:' .. message.from.id, 'last_name',
            message.from.last_name
        )
    end
    if message.chat.type ~= 'private' then
        redis:sadd(
            'chat:' .. message.chat.id .. ':users',
            message.from.id
        )
    end
    redis:incr('messages:' .. message.from.id .. ':' .. message.chat.id)
    return message
end

function statistics:on_message(message)
    if message.chat.type == 'private' then
        return
    end
    return mattata.send_message(
        message.chat.id,
        statistics.get_statistics(
            message.chat.id,
            message.chat.title,
            message.message_id
        ),
        'html'
    )
end

return statistics