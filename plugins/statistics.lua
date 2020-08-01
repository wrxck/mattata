--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local statistics = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function statistics:init()
    statistics.commands = mattata.commands(self.info.username):command('statistics'):command('stats'):command('morestats').table
    statistics.help = '/statistics - Shows statistical information about the current chat\'s top ten users (ordered by message count). Send /morestats to view the top 50 users. Alias: /stats.'
end

function statistics.reset_message_statistics(chat_id)
    if not chat_id or tonumber(chat_id) == nil then
        return false
    end
    local messages = redis:keys('messages:*:' .. chat_id)
    if not next(messages) then
        return false
    end
    for _, v in pairs(messages) do
        redis:del(v)
    end
    return true
end

function statistics.get_user_message_statistics(user_id, chat_id)
    return {
        ['messages'] = tonumber(redis:get('messages:' .. user_id .. ':' .. chat_id)) or 0,
        ['name'] = redis:hget('user:' .. user_id .. ':info', 'first_name'),
        ['id'] = user_id
    }
end

function statistics.get_message_statistics(message, language, more)
    if not message or not language then
        return language['errors']['generic']
    end
    local users = redis:smembers('chat:' .. message.chat.id .. ':users')
    local user_info = {}
    for i = 1, #users do
        local user = statistics.get_user_message_statistics(users[i], message.chat.id)
        if user.name and user.name ~= '' and user.messages > 0 then
            table.insert(user_info, user)
        end
    end
    table.sort(user_info, function(a, b)
        if a.messages and b.messages then
            return a.messages > b.messages
        end
    end)
    local total = 0
    for n, _ in pairs(user_info) do
        local message_count = user_info[n].messages
        total = total + message_count
    end
    local text = ''
    local output = {}
    local amount = more and 50 or 10
    for i = 1, amount do
        if i <= #user_info then
            table.insert(output, user_info[i])
        else
            break
        end
    end
    local count = 0
    for _, v in pairs(output) do
        count = count + 1
        local message_count = v.messages
        local percent = tostring(mattata.round((message_count / total) * 100, 1))
        text = text .. count .. '. ' .. mattata.get_formatted_user(v.id, v.name, 'html') .. ': <b>' .. mattata.comma_value(message_count) .. '</b> [' .. percent .. '%]\n'
    end
    text = text .. string.format('\n<em>I have seen %s/%s users in this group</em>', #redis:smembers('chat:' .. message.chat.id .. ':users'), mattata.get_chat_members_count(message.chat.id).result)
    return string.format(language['statistics']['2'], mattata.escape_html(message.chat.title), text, mattata.comma_value(total))
end

function statistics:on_message(message, _, language)
    if message.chat.type == 'private' then
        return false
    end
    local input = mattata.input(message.text)
    local output
    if input and input:lower() == 'reset' and mattata.is_group_admin(message.chat.id, message.from.id, true) then
        output = statistics.reset_message_statistics(message.chat.id) and language['statistics']['3'] or language['statistics']['4']
        return mattata.send_message(message.chat.id, output)
    end
    local more = message.text:match('^[/!#]morestats') and true or false
    output = statistics.get_message_statistics(message, language, more)
    if more then
        local success = mattata.send_message(message.from.id, output, 'html')
        if not success then
            return mattata.send_reply(message, 'Please [start a conversation with me](https://t.me/' .. self.info.username:lower() .. ') and try this command again!', true, true)
        end
        return mattata.send_reply(message, 'I\'ve sent you this information [via private chat](https://t.me/' .. self.info.username:lower() .. ')!', true, true)
    end
    return mattata.send_message(message.chat.id, output, 'html', true, true, true)
end

return statistics