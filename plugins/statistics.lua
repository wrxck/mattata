--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local statistics = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function statistics:init()
    statistics.commands = mattata.commands(self.info.username)
    :command('statistics')
    :command('stats').table
    statistics.help = '/statistics - Shows statistical information about the current chat\'s top ten users (ordered by message count). Alias: /stats.'
end

function statistics.get_name(user)
    if user.name
    then
        return user.name
    end
    local name = ''
    if user.first_name
    then
        name = user.first_name
    end
    if user.last_name
    then
        name = name .. ' ' .. user.last_name
    end
    return name
end

function statistics.reset_stats(chat_id)
    if not chat_id
    or tonumber(chat_id) == nil
    then
        return false
    end
    local messages = redis:keys('messages:*:' .. chat_id)
    for k, v in pairs(messages)
    do
        redis:del(v)
    end
    return true
end

function statistics.get_messages(id, chat)
    local info = {}
    local user = redis:hgetall('user:' .. id)
    info.messages = tonumber(
        redis:get('messages:' .. id .. ':' .. chat)
    )
    or 0
    info.name = statistics.get_name(user)
    return info
end

function statistics.get_statistics(chat_id, title, language)
    local users = redis:smembers('chat:' .. chat_id .. ':users')
    local user_info = {}
    for i = 1, #users
    do
        local user = statistics.get_messages(
            users[i],
            chat_id
        )
        if user.name
        and user.name ~= ''
        and user.messages > 0
        then
            table.insert(
                user_info,
                user
            )
        end
    end
    table.sort(
        user_info,
        function(a, b)
            if a.messages
            and b.messages
            then
                return a.messages > b.messages
            end
        end
    )
    local total = 0
    for n, user in pairs(user_info)
    do
        local message_count = user_info[n].messages
        total = total + message_count
    end
    local text = ''
    local output = {}
    for i = 1, 10
    do
        table.insert(
            output,
            user_info[i]
        )
    end
    for k, v in pairs(output)
    do
        local message_count = v.messages
        local percent = tostring(
            mattata.round(
                (message_count / total) * 100,
                1
            )
        )
        text = text .. mattata.escape_html(v.name) .. ': <b>' .. mattata.comma_value(message_count) .. '</b> [' .. percent .. '%]\n'
    end
    if not text
    or text == ''
    then
        return language['statistics']['1']
    end
    return string.format(
        language['statistics']['2'],
        mattata.escape_html(title),
        text,
        mattata.comma_value(total)
    )
end

function statistics:process_message(message)
    if message.left_chat_member
    then
        redis:srem(
            'chat:' .. message.chat.id .. ':users',
            message.left_chat_member.id
        )
    end
    if message.chat.type ~= 'private'
    and not redis:sismember(
        'chat:' .. message.chat.id .. ':users',
        message.from.id
    )
    then
        redis:sadd(
            'chat:' .. message.chat.id .. ':users',
            message.from.id
        )
    end
    redis:incr('messages:' .. message.from.id .. ':' .. message.chat.id)
    return true
end

function statistics:on_message(message, configuration, language)
    if message.chat.type == 'private'
    then
        return
    end
    local input = mattata.input(message.text)
    if input
    and input:lower() == 'reset'
    and mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    )
    then
        return mattata.send_message(
            message.chat.id,
            statistics.reset_stats(message.chat.id)
            and language['statistics']['3']
            or language['statistics']['4']
        )
    end
    return mattata.send_message(
        message.chat.id,
        statistics.get_statistics(
            message.chat.id,
            message.chat.title,
            language
        ),
        'html'
    )
end

return statistics