--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local antispam = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function antispam:init()
    antispam.commands = mattata.commands(self.info.username):command('antispam').table
end

antispam.media_types = {
    'text',
    'forwarded',
    'sticker',
    'photo',
    'video',
    'location',
    'voice',
    'game',
    'venue',
    'video note',
    'invoice',
    'contact'
}

antispam.default_values = {
    ['text'] = 8,
    ['forwarded'] = 16,
    ['sticker'] = 4,
    ['photo'] = 4,
    ['video'] = 4,
    ['location'] = 4,
    ['voice'] = 4,
    ['game'] = 2,
    ['venue'] = 4,
    ['video note'] = 4,
    ['invoice'] = 2,
    ['contact'] = 2
}

function antispam.get_keyboard(chat_id)
    local status = redis:hget(
        'chat:' .. chat_id .. ':settings',
        'antispam'
    )
    and true
    or false
    local caption = status
    and 'Disable'
    or 'Enable'
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = caption,
                ['callback_data'] = 'antispam:' .. chat_id .. ':' .. caption:lower()
            }
        }
    )
    if status
    then
        for n, media in pairs(antispam.media_types)
        do
            local current = mattata.get_value(
                chat_id,
                media .. ' limit'
            )
            or antispam.default_values[media]
            table.insert(
                keyboard.inline_keyboard,
                {
                    {
                        ['text'] = media:gsub('^%l', string.upper),
                        ['callback_data'] = 'antispam:nil'
                    },
                    {
                        ['text'] = '-',
                        ['callback_data'] = 'antispam:' .. chat_id .. ':limit:' .. media .. ':' .. (
                            tonumber(current) - 1
                        )
                    },
                    {
                        ['text'] = tostring(current),
                        ['callback_data'] = 'antispam:nil'
                    },
                    {
                        ['text'] = '+',
                        ['callback_data'] = 'antispam:' .. chat_id .. ':limit:' .. media .. ':' .. (
                            tonumber(current) + 1
                        )
                    }
                }
            )
        end
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = mattata.symbols.back .. ' All Administration Settings',
                ['callback_data'] = 'administration:' .. chat_id .. ':back'
            }
        }
    )
    return keyboard
end

function antispam.check_links(message, process_type)
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
    if process_type == 'whitelist'
    then
        local count = 0
        for k, v in pairs(links)
        do
            if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. v)
            then
                redis:set(
                    'whitelisted_links:' .. message.chat.id .. ':' .. v,
                    true
                )
                count = count + 1
            end
        end
        return string.format(
            '%s link%s ha%s been whitelisted in this chat!',
            count,
            count == 1
            and ''
            or 's',
            count == 1
            and 's'
            or 've'
        )
    elseif process_type == 'check'
    then
        for k, v in pairs(links)
        do
            if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. v)
            and v:lower() ~= 'username'
            and v:lower() ~= 'isiswatch'
            and v:lower() ~= 'mattata'
            and v:lower() ~= 'telegram'
            then
                return true
            end
        end
        return false
    end
end

function antispam.is_user_spamming(message)
    if message.media_type == ''
    then
        return false
    end
    local limit = mattata.get_value(
        message.chat.id,
        message.media_type .. ' limit'
    )
    or antispam.default_values[message.media_type]
    local current = redis:get('antispam:' .. message.media_type .. ':' .. message.chat.id .. ':' .. message.from.id)
    or 1
    redis:setex(
        'antispam:' .. message.media_type .. ':' .. message.chat.id .. ':' .. message.from.id,
        5,
        tonumber(current) + 1
    )
    if tonumber(current) == tonumber(limit)
    then
        return true, message.media_type
    end
    return false
end

function antispam:process_message(message, configuration, language)
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
        'antispam'
    )
    then
        return false
    end
    local is_spamming, media_type = antispam.is_user_spamming(message)
    if not is_spamming
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
                '<pre>%s [%s] has kicked %s [%s] from %s [%s] for hitting the configured anti-spam limit for [%s] media.</pre>',
                mattata.escape_html(self.info.first_name),
                self.info.id,
                mattata.escape_html(message.from.first_name),
                message.from.id,
                mattata.escape_html(message.chat.title),
                message.chat.id,
                media_type
            ),
            'html'
        )
    end
    return mattata.send_message(
        message,
        string.format(
            'Kicked %s for hitting the configured antispam limit for [%s] media.',
            message.from.username
            and '@' .. message.from.username
            or message.from.first_name,
            media_type
        )
    )
end

function antispam:on_callback_query(callback_query, message, configuration, language)
    local chat_id = message.chat.type == 'supergroup'
    and message.chat.id
    or callback_query.data:match('^(%-%d+):?')
    if not chat_id
    then
        return mattata.answer_callback_query(
            callback_query.id,
            language['errors']['generic']
        )
    elseif not mattata.is_group_admin(
        chat_id,
        callback_query.from.id
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            language['errors']['admin']
        )
    end
    local keyboard = false
    if callback_query.data:match('^%-%d+$')
    then
        keyboard = antispam.get_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:limit:.-:.-$')
    then
        local spam_type, limit = callback_query.data:match('^%-%d+:limit:(.-):(.-)$')
        if tonumber(limit) > 100
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum limit is 100.'
            )
        elseif tonumber(limit) < 1
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum limit is 1.'
            )
        elseif tonumber(limit) == nil
        then
            return
        end
        redis:hset(
            'chat:' .. chat_id .. ':values',
            spam_type .. ' limit',
            tonumber(limit)
        )
        keyboard = antispam.get_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:disable$')
    then
        redis:hdel(
            'chat:' .. chat_id .. ':settings',
            'antispam'
        )
        keyboard = antispam.get_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:enable$')
    then
        redis:hset(
            'chat:' .. chat_id .. ':settings',
            'antispam',
            true
        )
        keyboard = antispam.get_keyboard(chat_id)
    end
    return mattata.edit_message_reply_markup(
        message.chat.id,
        message.message_id,
        nil,
        json.encode(keyboard)
    )
end

function antispam:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    end
    return mattata.send_message(
        message.chat.id,
        'Modify the anti-spam settings for ' .. message.chat.title .. ' below:',
        nil,
        true,
        false,
        nil,
        json.encode(
            antispam.get_keyboard(message.chat.id)
        )
    )
end

return antispam