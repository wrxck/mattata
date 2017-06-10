--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local antilink = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function antilink.check_links(message)
    local links = {}
    if message.entities
    then
        for i = 1, #message.entities
        do
            if message.entities[i].type == 'text_link'
            then
                message.text = message.text .. ' ' .. message.entities[i].url
            end
        end
    end
    for n in message.text:lower():gmatch('%@[%w_]+')
    do
        table.insert(
            links,
            n:match('^%@([%w_]+)$')
        )
    end
    for n in message.text:lower():gmatch('t%.me/joinchat/[%w_]+')
    do
        table.insert(
            links,
            n:match('/(joinchat/[%w_]+)$')
        )
    end
    for n in message.text:lower():gmatch('t%.me/[%w_]+')
    do
        if not n:match('/joinchat$')
        then
            table.insert(
                links,
                n:match('/([%w_]+)$')
            )
        end
    end
    for n in message.text:lower():gmatch('telegram%.me/joinchat/[%w_]+')
    do
        table.insert(
            links,
            n:match('/(joinchat/[%w_]+)$')
        )
    end
    for n in message.text:lower():gmatch('telegram%.me/[%w_]+')
    do
        if not n:match('/joinchat$')
        then
            table.insert(
                links,
                n:match('/([%w_]+)$')
            )
        end
    end
    for n in message.text:lower():gmatch('telegram%.dog/joinchat/[%w_]+')
    do
        table.insert(
            links,
            n:match('/(joinchat/[%w_]+)$')
        )
    end
    for n in message.text:lower():gmatch('telegram%.dog/[%w_]+')
    do
        if not n:match('/joinchat$')
        then
            table.insert(
                links,
                n:match('/([%w_]+)$')
            )
        end
    end
    for k, v in pairs(links)
    do
        if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. v)
        and v:lower() ~= 'username'
        and v:lower() ~= 'isiswatch'
        and v:lower() ~= 'mattata'
        and v:lower() ~= 'telegram'
        then
            local success = mattata.get_chat(v)
            if (
                success
                and success.result
                and success.result.type ~= 'private'
            )
            or v:match('^joinchat/')
            then
                return true
            end
        end
    end
    return false
end

function antilink:process_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    or mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    or mattata.is_global_admin(message.from.id)
    or not mattata.get_setting(
        message.chat.id,
        'use administration'
    )
    or not mattata.get_setting(
        message.chat.id,
        'antilink'
    )
    or not antilink.check_links(message)
    then
        return false
    end
    local action = mattata.get_setting(
        message.chat.id,
        'ban not kick'
    )
    and mattata.ban_chat_member
    or mattata.kick_chat_member
    local success = action(
        message.chat.id,
        message.from.id
    )
    if not success
    then
        return false
    elseif mattata.get_setting(
        message.chat.id,
        'log administrative actions'
    )
    then
        mattata.send_message(
            mattata.get_log_chat(message.chat.id),
            string.format(
                '<pre>%s [%s] has kicked %s [%s] from %s [%s] for sending Telegram invite link(s)</pre>',
                mattata.escape_html(self.info.first_name),
                self.info.id,
                mattata.escape_html(message.from.first_name),
                message.from.id,
                mattata.escape_html(message.chat.title),
                message.chat.id
            ),
            'html'
        )
    end
    return mattata.send_message(
        message,
        string.format(
            'Kicked %s for sending Telegram invite link(s).',
            message.from.username
            and '@' .. message.from.username
            or message.from.first_name
        )
    )
end

return antilink