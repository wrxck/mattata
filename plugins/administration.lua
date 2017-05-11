--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local administration = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function administration:init()
    administration.commands = mattata.commands(self.info.username)
    :command('administration')
    :command('antispam')
    :command('admins')
    :command('staff')
    :command('groups')
    :command('chats')
    :command('links')
    :command('whitelistlink')
    :command('link')
    :command('setlink')
    :command('rules')
    :command('setrules')
    :command('pin')
    :command('report')
    :command('ops')
    :command('tempban').table
end

function administration.insert_keyboard_row(keyboard, text1, callback1, text2, callback2, text3, callback3)
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = text1,
                ['callback_data'] = callback1
            },
            {
                ['text'] = text2,
                ['callback_data'] = callback2
            },
            {
                ['text'] = text3,
                ['callback_data'] = callback3
            }
        }
    )
    return keyboard
end

function administration.get_setting(chat_id, setting)
    if not chat_id
    or not setting
    or not redis:hget(
        'chat:' .. chat_id .. ':settings',
        setting
    )
    then
        return false
    end
    return true
end

function administration.toggle_setting(chat_id, setting, value)
    if not chat_id
    or not setting
    or not redis:hget(
        'chat:' .. chat_id .. ':settings',
        setting
    )
    then
        return redis:hset(
            'chat:' .. chat_id .. ':settings',
            setting,
            value or true
        )
    end
    return redis:hdel(
        'chat:' .. chat_id .. ':settings',
        setting
    )
end

function administration.get_initial_keyboard(chat_id)
   if not administration.get_setting(
       chat_id,
       'use administration'
    )
    then
        return mattata.inline_keyboard()
        :row(
            mattata.row()
            :callback_data_button(
                'Enable Administration',
                'administration:' .. chat_id .. ':toggle'
            )
        )
    end
    return mattata.inline_keyboard()
    :row(
        mattata.row()
        :callback_data_button(
            'Disable Administration',
            'administration:' .. chat_id .. ':toggle'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Anti-Spam Settings',
            'administration:' .. chat_id .. ':antispam'
        )
        :callback_data_button(
            'Warning Settings',
            'administration:' .. chat_id .. ':warnings'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Arabic/RTL',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'rtl'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':rtl'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Welcome Message',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'welcome message'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':welcome_message'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Send Rules On Join?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'rules on join'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':rules'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Anti-Bot',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'antibot'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':antibot'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Anti-Link',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'antilink'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':antilink'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Anti-Spam Action',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'ban not kick'
            )
            and 'Ban'
            or 'Kick',
            'administration:' .. chat_id .. ':action'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Log Administrative Actions?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'log administrative actions'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':log'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Delete Commands?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'delete commands'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':delete_commands'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Back',
            'help:settings'
        )
    )
end

function administration.get_antispam_keyboard(chat_id)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current = administration.get_message_limit(
        chat_id,
        'text'
    )
    local lower = tonumber(current) - 1
    local higher = tonumber(current) + 1
    local forwarded_current = administration.get_message_limit(
        chat_id,
        'forwarded'
    )
    local forwarded_lower = tonumber(forwarded_current) - 1
    local forwarded_higher = tonumber(forwarded_current) + 1
    local stickers_current = administration.get_message_limit(
        chat_id,
        'stickers'
    )
    local stickers_lower = tonumber(stickers_current) - 1
    local stickers_higher = tonumber(stickers_current) + 1
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Max messages per 5s:',
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':limit:text:' .. lower,
        tostring(current),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':limit:text:' .. higher
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Max forwarded messages per 5s:',
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':limit:forwarded:' .. forwarded_lower,
        tostring(forwarded_current),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':limit:forwarded:' .. forwarded_higher
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Max stickers per 5s:',
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':limit:stickers:' .. stickers_lower,
        tostring(stickers_current),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':limit:stickers:' .. stickers_higher
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Back',
                ['callback_data'] = 'administration:' .. chat_id .. ':back'
            }
        }
    )
    return keyboard
end

function administration.get_warnings(chat_id)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current = redis:hget(
        string.format(
            'chat:%s:settings',
            chat_id
        ),
        'max warnings'
    ) or 3
    local ban_kick_status = administration.get_hash_status(
        chat_id,
        'ban_kick'
    )
    local action = 'ban'
    if not ban_kick_status then
        action = 'kick'
    end
    local lower = tonumber(current) - 1
    local higher = tonumber(current) + 1
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = string.format(
                    'Number of warnings until %s:',
                    action
                ),
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':max_warnings:' .. lower,
        tostring(current),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':max_warnings:' .. higher
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Back',
                ['callback_data'] = 'administration:' .. chat_id .. ':back'
            }
        }
    )
    return keyboard
end

function administration.get_message_limit(chat_id, spam_type)
    local hash = mattata.get_redis_hash(
        chat_id,
        'administration'
    )
    local limit = redis:hget(
        hash,
        spam_type
    )
    if not limit
    or tonumber(limit) == nil
    then
        if spam_type == 'text'
        then
            return 8
        elseif spam_type == 'forwarded'
        then
            return 16
        elseif spam_type == 'stickers'
        then
            return 4
        end
    end
    return tonumber(limit)
end

function administration.get_hash_status(chat_id, hash_type)
    if redis:get('administration:' .. chat_id .. ':' .. hash_type)
    then
        return true
    end
    return false
end

function administration.check_links(message, process_type)
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
            then
                if not v:match('^joinchat/')
                then
                    local resolved = mattata.get_chat('@' .. v)
                    if resolved
                    then
                        return true
                    end
                else
                    return true
                end
            end
        end
        return false
    end
end

function administration.is_user_spamming(message) -- Checks if a user is spamming, and returns two boolean values.
    if mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return false
    end
    local messages = redis:get('administration:text:' .. message.chat.id .. ':' .. message.from.id)
    local forwarded = redis:get('administration:forwarded:' .. message.chat.id .. ':' .. message.from.id)
    local stickers = redis:get('administration:stickers:' .. message.chat.id .. ':' .. message.from.id)
    if redis:hget(
        'chat:' .. message.chat.id .. ':settings',
        'antilink'
    )
    and administration.check_links(
        message,
        'check'
    )
    then
        return true, 'links'
    end
    local limit = administration.get_message_limit(
        message,
        'text'
    )
    local forwarded_limit = administration.get_message_limit(
        message,
        'forwarded'
    )
    local stickers_limit = administration.get_message_limit(
        message,
        'stickers'
    )
    if message.forward_from
    or message.forward_from_chat
    then
        if tonumber(forwarded) == nil
        then
            forwarded = 1
        end
        redis:setex(
            'administration:forwarded:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(forwarded) + 1
        )
        if tonumber(forwarded) == tonumber(forwarded_limit)
        then
            return true, 'forwarded messages'
        end
    elseif message.text
    and not message.is_media
    then
        if tonumber(messages) == nil
        then
            messages = 1
        end
        redis:setex(
            'administration:text:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(messages) + 1
        )
        if tonumber(messages) == tonumber(limit)
        then
            return true, 'text messages'
        end
    elseif message.sticker
    then
        if tonumber(stickers) == nil
        then
            stickers = 1
        end
        redis:setex(
            'administration:stickers:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(stickers) + 1
        )
        if tonumber(stickers) == tonumber(stickers_limit)
        then
            return true, 'stickers'
        end
    end
    if administration.get_setting(
        message.chat.id,
        'rtl'
    )
    and message.text:match('[\216-\219][\128-\191]')
    then -- Match Arabic and RTL characters.
        return true, 'Arabic/RTL characters'
    end
    return false, nil
end

function administration.new_chat(message)
    local link, title = message.text:match('^/chats new (.-) (.-)$')
    if not link or not title then
        return
    elseif not link:match('https://t%.me/(.-)$') then
        return
    end
    local entry = json.encode(
        {
            ['link'] = tostring(link),
            ['title'] = tostring(title)
        }
    )
    for k, v in pairs(redis:smembers('mattata:configuration:chats')) do
        if not v then
            return
        elseif not json.decode(v).link or not json.decode(v).title then
            return
        elseif json.decode(v).link == link then
            return mattata.send_reply(
                message,
                'This link already exists in the database, under the name ' .. json.decode(v).title .. '!'
            )
        elseif json.decode(v).title == title then
            return mattata.send_reply(
                message,
                'This title already exists in the database, with the link ' .. json.decode(v).link .. '!'
            )
        end
    end
    redis:sadd(
        'mattata:configuration:chats',
        entry
    )
    return mattata.send_reply(
        message,
        'Added that link to the database, under the name ' .. title .. '!'
    )
end

function administration.del_chat(message)
    local title = message.text:match('^/chats del (.-)$')
    if not title then
        return
    end
    for k, v in pairs(redis:smembers('mattata:configuration:chats')) do
        if not v then
            return
        end
        if not json.decode(v).link or not json.decode(v).title then
            return
        elseif json.decode(v).title == title then
            redis:srem(
                'mattata:configuration:chats',
                v
            )
            return mattata.send_reply(
                message,
                'Deleted ' .. title .. ', and its matching link from the database!'
            )
        end
    end
    return mattata.send_reply(
        message,
        'There were no entries found in the database matching "' .. title .. '"!'
    )
end

function administration.get_chats(message)
    local input = mattata.input(message.text)
    local output = {}
    for k, v in pairs(redis:smembers('mattata:configuration:chats')) do
        if v and json.decode(v).link and json.decode(v).title then
            local link, title = json.decode(v).link, json.decode(v).title
            if input then
                local validate = pcall(
                    function()
                        return title:match(input)
                    end
                )
                if not validate then
                    return mattata.send_reply(
                        message,
                        'Your search query contains a malformed Lua pattern! If you\'re not sure what this means, try searching without any symbols.'
                    )
                end
            end
            if (input and title:match(input)) or not input then
                table.insert(
                    output,
                    string.format(
                        '• <a href="%s">%s</a>',
                        mattata.escape_html(link),
                        mattata.escape_html(title)
                    )
                )
            end
        end
    end
    if not next(output) then
        local output = 'No groups were found. If you\'d like your group to appear here, contact @wrxck0.'
        if input then
            output = string.format(
                'No groups were found matching "%s"! Use /groups to view a complete list of available groups.',
                input
            )
        end
        return mattata.send_reply(
            message,
            output
        )
    end
    table.sort(output)
    output = table.concat(
        output,
        '\n'
    )
    if input then
        output = string.format(
            'Groups found matching "%s":\n',
            mattata.escape_html(input)
        ) .. output
    end
    mattata.send_message(
        message,
        output,
        'html'
    )
end

function administration.tempban(message)
    local input = mattata.input(message.text)
    if (
        not input
        and not message.reply
    )
    or (
        input
        and not message.reply
        and not input:match('^%@%a+ %d*')
    )
    or (
        input
        and message.reply
        and not input:match('^%d*')
    )
    then
        return mattata.send_reply(
            message,
            'Please specify the user you\'d like to temp-ban, and how long you\'d like to temp-ban them for. This must be sent in the format /tempban [user] <hours> [reason]. If a user isn\'t specified then you must use this command in reply to the user you\'d like to temp-ban.'
        )
    end
    local user = input
    and input:match('^(%@%a+) %d*')
    or message.reply.from.id
    if tonumber(user) == nil
    then
        user = mattata.get_user(user)
        if not user
        then
            return mattata.send_reply(
                message,
                'I don\'t recognise that user!'
            )
        end
        user = user.result.id
    end
    if mattata.is_group_admin(
        message.chat.id,
        user
    )
    then
        return mattata.send_reply(
            message,
            'I can\'t temp-ban that user because they\'re a staff member of this chat!'
        )
    elseif not mattata.get_chat_member(
        message.chat.id,
        user
    )
    then
        return mattata.send_reply(
            message,
            'I can\'t temp-ban that user because they\'re not a member of this chat!'
        )
    elseif redis:sismember(
        string.format(
            'chat:%s:tempbanned',
            message.chat.id
        ),
        user
    )
    then
        return mattata.send_reply(
            message,
            'That user is already temp-banned!'
        )
    end
    local user_info = mattata.get_chat_member(
        message.chat.id,
        user
    )
    local reason = input:match('%d* (.-)$')
    or false
    local hours = input:match('^%@%a+ (%d*)$')
    or input:match('^%@%a+ (%d*) .-$')
    or input:match('^(%d*)$')
    or input:match('^(%d*) .-$')
    if tonumber(hours) == nil
    or tonumber(hours) < 1
    or tonumber(hours) > 168
    then
        return mattata.send_reply(
            message,
            'The minimum time you can temp-ban a user for is 1 hour. The maximum time you can temp-ban a user for is 168 hours (1 week).'
        )
    end
    local success = mattata.ban_chat_member(
        message.chat.id,
        user
    )
    if not success
    then
        return mattata.send_reply(
            message,
            'I can\'t temp-ban that user because I\'m not an administrator in this chat!'
        )
    end
    redis:hset(
        'tempbanned',
        os.time() + (tonumber(hours) * 3600),
        string.format(
            '%s:%s',
            message.chat.id,
            user
        )
    )
    redis:sadd(
        string.format(
            'chat:%s:tempbanned',
            message.chat.id
        ),
        user
    )
    local hours_formatted = hours .. ' hour'
    if tonumber(hours) > 1
    then
        hours_formatted = hours_formatted .. 's'
    end
    local output = string.format(
        '%s [%s] has temp-banned %s [%s] from %s [%s] for %s.',
        message.from.first_name,
        message.from.id,
        user_info.result.user.first_name,
        user_info.result.user.id,
        message.chat.title,
        message.chat.id,
        hours_formatted
    )
    if reason ~= false
    then
        output = output .. '\nReason: ' .. reason
    end
    if administration.get_setting(
        message.chat.id,
        'log administrative actions'
    )
    then
        mattata.send_message(
            configuration.log_channel,
            string.format(
                '<pre>%s</pre>',
                mattata.escape_html(output)
            ),
            'html'
        )
    end
    return mattata.send_reply(
        message,
        string.format(
            '<pre>%s</pre>',
            mattata.escape_html(output)
        ),
        'html'
    )
end

function administration.warn(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator to use this command!'
        )
    elseif not message.reply then
        return mattata.send_reply(
            message,
            'You must use this command via reply to the targeted user\'s message.'
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        message.reply.from.id
    ) then
        return mattata.send_reply(
            message,
            'The targeted user is an administrator in this chat.'
        )
    end
    local name = message.reply.from.first_name
    local hash = 'chat:' .. message.chat.id .. ':warnings'
    local amount = redis:hincrby(
        hash,
        message.reply.from.id,
        1
    )
    local maximum = redis:get(
        string.format(
            'administration:%s:max_warnings',
            message.chat.id
        )
    ) or 3
    local text, res
    amount, maximum = tonumber(amount), tonumber(maximum)
    if amount >= maximum then
        text = message.reply.from.first_name .. ' was banned for reaching the maximum number of allowed warnings (' .. maximum .. ').'
        local success = mattata.ban_chat_member(
            message.chat.id,
            message.reply.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban that user. Please ensure that I\'m an administrator and that the targeted user isn\'t.'
            )
        end
        redis:hdel(
            'chat:' .. message.chat.id .. ':warnings',
            message.reply.from.id
        )
        return mattata.send_message(
            message,
            text
        )
    end
    local difference = maximum - amount
    text = '*%s* has been warned `[%d/%d]`'
    local reason = mattata.input(message.text)
    if reason then
        text = text .. '\n*Reason:* ' .. mattata.escape_markdown(reason)
    end
    text = text:format(
        mattata.escape_markdown(name),
        amount,
        maximum
    )
    local keyboard = json.encode(
        {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = 'Reset Warnings',
                        ['callback_data'] = string.format(
                            'administration:warn:reset:%s:%s',
                            message.chat.id,
                            message.reply.from.id
                        )
                    },
                    {
                        ['text'] = 'Remove 1 Warning',
                        ['callback_data'] = string.format(
                            'administration:warn:remove:%s:%s',
                            message.chat.id,
                            message.reply.from.id
                        )
                    }
                }
            }
        }
    )
    return mattata.send_message(
        message,
        text,
        'markdown',
        true,
        false,
        nil,
        keyboard
    )
end

function administration:on_callback_query(callback_query, message, configuration)
    if callback_query.data == 'nil' then
        return mattata.answer_callback_query(callback_query.id)
    elseif not mattata.is_group_admin(
        callback_query.data:match('^(%-%d+)'),
        callback_query.from.id
    ) then
        return mattata.answer_callback_query(
            callback_query.id,
            'You\'re not an administrator in that chat!'
        )
    end
    local keyboard
    if callback_query.data:match('^%-%d+:antispam$') then
        local chat_id = callback_query.data:match('^(%-%d+):antispam$')
        keyboard = administration.get_antispam_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:limit:.-:.-$') then
        local chat_id, spam_type, limit = callback_query.data:match('^(%-%d+):limit:(.-):(.-)$')
        local max_limit, min_limit
        if spam_type == 'text' then
            max_limit, min_limit = 16, 2
        elseif spam_type == 'forwarded' then
            max_limit, min_limit = 32, 1
        elseif spam_type == 'stickers' then
            max_limit, min_limit = 8, 1
        end
        if tonumber(limit) > tonumber(max_limit) then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum limit is ' .. max_limit .. '.'
            )
        elseif tonumber(limit) < tonumber(min_limit) then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum limit is ' .. min_limit .. '.'
            )
        elseif tonumber(limit) == nil then
            return
        end
        local hash = mattata.get_redis_hash(
            chat_id,
            'administration'
        )
        redis:hset(
            hash,
            spam_type,
            tonumber(limit)
        )
        keyboard = administration.get_antispam_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:warnings$') then
        local chat_id = callback_query.data:match('^(%-%d+):warnings$')
        keyboard = administration.get_warnings(chat_id)
    elseif callback_query.data:match('^%-%d+:max_warnings:.-$') then
        local chat_id, max_warnings = callback_query.data:match('^(%-%d+):max_warnings:(.-)$')
        if tonumber(max_warnings) > configuration.administration.warnings.maximum then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum number of warnings is 10.'
            )
        elseif tonumber(max_warnings) < configuration.administration.warnings.minimum then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum number of warnings is 2.'
            )
        elseif tonumber(max_warnings) == nil then
            return
        end
        redis:hset(
            string.format(
                'chat:%s:settings',
                chat_id
            ),
            'max warnings',
            tonumber(max_warnings)
        )
        keyboard = administration.get_warnings(chat_id)
    elseif callback_query.data:match('^%-%d+:toggle$') then
        local chat_id = callback_query.data:match('^(%-%d+):toggle$')
        administration.toggle_setting(
            chat_id,
            'use administration'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:rtl$') then
        local chat_id = callback_query.data:match('^(%-%d+):rtl$')
        administration.toggle_setting(
            chat_id,
            'rtl'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:rules$') then
        local chat_id = callback_query.data:match('^(%-%d+):rules$')
        administration.toggle_setting(
            chat_id,
            'rules on join'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:inactive$') then
        local chat_id = callback_query.data:match('^(%-%d+):inactive$')
        administration.toggle_setting(
            chat_id,
            'remove inactive users'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:action$') then
        local chat_id = callback_query.data:match('^(%-%d+):action$')
        administration.toggle_setting(
            chat_id,
            'ban not kick'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:antibot$') then
        local chat_id = callback_query.data:match('^(%-%d+):antibot$')
        administration.toggle_setting(
            chat_id,
            'antibot'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:antilink$') then
        local chat_id = callback_query.data:match('^(%-%d+):antilink$')
        administration.toggle_setting(
            chat_id,
            'antilink'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:welcome_message$') then
        local chat_id = callback_query.data:match('^(%-%d+):welcome_message$')
        administration.toggle_setting(
            chat_id,
            'welcome message'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:delete_commands$') then
        local chat_id = callback_query.data:match('^(%-%d+):delete_commands$')
        administration.toggle_setting(
            chat_id,
            'delete commands'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:log$') then
        local chat_id = callback_query.data:match('^(%-%d+):log$')
        administration.toggle_setting(
            chat_id,
            'log administrative actions'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:enable_admins_only$') then
        local chat_id = callback_query.data:match('^(%-%d+):enable_admins_only$')
        redis:set(
            string.format(
                'administration:%s:admins_only',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:disable_admins_only$') then
        local chat_id = callback_query.data:match('^(%-%d+):disable_admins_only$')
        redis:del('administration:' .. chat_id .. ':admins_only')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:ahelp$') then
        keyboard = administration.get_help_keyboard(callback_query.data:match('^(%-%d+):ahelp$'))
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration.get_help_text('back'),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^%-%d+:ahelp:.-$') then
        return administration.on_help_callback_query(
            callback_query,
            callback_query.data:match('^%-%d+:ahelp:.-$')
        )
    elseif callback_query.data:match('^%-%d+:back$') then
        keyboard = administration.get_initial_keyboard(callback_query.data:match('^(%-%d+):back$'))
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'dismiss_disabled_message' then
        redis:set(
            string.format(
                'administration:%s:dismiss_disabled_message',
                message.chat.id
            ),
            true
        )
        return mattata.answer_callback_query(
            callback_query.id,
            [[You will no longer be reminded that the administration plugin is disabled. To enable it, use /administration.]],
            true
        )
    else
        return
    end
    return mattata.edit_message_reply_markup(
        message.chat.id,
        message.message_id,
        nil,
        json.encode(keyboard)
    )
end

function administration.pin(message)
    if message.chat.type ~= 'supergroup' then
        return
    end
    local input = mattata.input(message.text)
    local last_pin = redis:get(
        string.format(
            'administration:%s:pin',
            message.chat.id
        )
    )
    local pin_exists = true
    if not input then
        if not last_pin then
            return mattata.send_reply(
                message,
                [[You haven't set a pin before. Use /pin <text> to set one. Markdown formatting is supported.]]
            )
        end
        local success = mattata.send_message(
            message,
            'Here is the last message generated using /pin.',
            nil,
            true,
            false,
            last_pin
        )
        if not success then
            pin_exists = false
            return mattata.send_reply(
                message,
                [[I found an existing pin in the database, but the message I sent it in seems to have been deleted, and I can't find it anymore. You can set a new one with /pin <text>. Markdown formatting is supported.]]
            )
        end
        return
    end
    local success = mattata.edit_message_text(
        message.chat.id,
        last_pin,
        input,
        'markdown'
    )
    if not success then
        mattata.send_reply(
            message,
            [[There was an error whilst updating your pin. Either the text you entered contained invalid Markdown syntax, or the pin has been deleted. I'm now going to try and send you a new pin, which you'll be able to find below - if you need to modify it then, after ensuring the message still exists, use /pin <text>.]]
        )
        local new_pin = mattata.send_message(
            message,
            input,
            'markdown',
            true,
            false
        )
        if not new_pin then
            return mattata.send_reply(
                message,
                [[I couldn't send that text because it contains invalid Markdown syntax.]]
            )
        end
        redis:set(
            string.format(
                'administration:%s:pin',
                message.chat.id
            ),
            new_pin.result.message_id
        )
        last_pin = new_pin.result.message_id
    end
    return mattata.send_message(
        message,
        'Click here to see the pin, updated to contain the text you gave me.',
        nil,
        true,
        false,
        last_pin
    )
end

function administration:process_message(message)
    if mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and not mattata.is_global_admin(message.from.id) then -- Don't iterate over the user's messages if they're an administrator in the group or a globally configured owner.
        return
    end
    local is_spamming, media_type = administration.is_user_spamming(message)
    if not is_spamming then
        return
    end
    local success, executed_action
    if redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'ban not kick'
    ) then
        success = mattata.ban_chat_member(
            message.chat.id,
            message.from.id
        )
        executed_action = 'banned'
    else
        success = mattata.kick_chat_member(
            message.chat.id,
            message.from.id
        )
        executed_action = 'kicked'
    end
    if not success then
        return
    elseif redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'log administrative actions'
    ) then
        mattata.send_message(
            configuration.log_channel,
            string.format(
                '<pre>%s [%s] has %s %s [%s] from %s [%s] for sending too many %s.</pre>',
                mattata.escape_html(self.info.first_name),
                self.info.id,
                executed_action,
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
            '%s %s%s for sending too many %s.',
            executed_action:gsub('^%l', string.upper),
            message.from.username and '@' or '',
            message.from.username or message.from.first_name,
            media_type
        )
    )
end

function administration.get_welcome_message(chat_id)
    return redis:hget(
        'chat:' .. chat_id .. ':values',
        'welcome message'
    )
end

function administration:on_new_chat_member(message)
    if message.new_chat_member.id == self.info.id then
        return mattata.send_message(
            message,
            string.format(
                'Thanks for adding me to %s, %s! I can be used just the way I am, but if you want to enable my administration functionality, use /administration. To disable my AI functionality, use /plugins.',
                message.chat.title,
                message.from.first_name
            )
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and administration.get_setting(
        message.chat.id,
        'antibot'
    ) and message.new_chat_member.username and message.new_chat_member.username:lower():match('bot$') and message.new_chat_member.id ~= message.from.id then
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.new_chat_member.id
        )
        if success then
            if configuration.log_admin_actions and configuration.log_channel ~= '' then
                mattata.send_message(
                    configuration.log_channel,
                    string.format(
                        '<pre>%s [%s] has kicked %s [%s] from %s [%s] because anti-bot is enabled.</pre>',
                        mattata.escape_html(self.info.first_name),
                        self.info.id,
                        mattata.escape_html(message.new_chat_member.first_name),
                        message.new_chat_member.id,
                        mattata.escape_html(message.chat.title),
                        message.chat.id
                    ),
                    'html'
                )
            end
            return mattata.send_message(
                message,
                string.format(
                    'Kicked @%s because anti-bot is enabled.',
                    message.new_chat_member.username
                )
            )
        end
    elseif not administration.get_setting(
        message.chat.id,
        'welcome message'
    ) then
        return
    end
    local name = message.new_chat_member.first_name
    if message.new_chat_member.last_name then
        name = name .. ' ' .. message.new_chat_member.last_name
    end
    name = name:gsub('%%', '%%%%')
    name = mattata.escape_markdown(name)
    local title = message.chat.title:gsub('%%', '%%%%')
    title = mattata.escape_markdown(title)
    username = message.new_chat_member.username and '@' .. message.new_chat_member.username or name
    local welcome_message = administration.get_welcome_message(message.chat.id) or configuration.join_messages[math.random(#configuration.join_messages)]:gsub('NAME', name)
    welcome_message = welcome_message:gsub('%$user_id', message.new_chat_member.id):gsub('%$chat_id', message.chat.id):gsub('%$name', name):gsub('%$title', title):gsub('%$username', username)
    local keyboard = false
    if administration.get_setting(
        message.chat.id,
        'rules on join'
    ) then
        keyboard = mattata.inline_keyboard():row(
            mattata.row():url_button(
                utf8.char(128218) .. ' Group Rules',
                'https://t.me/' .. self.info.username .. '?start=' .. message.chat.id .. '_rules'
            )
        )
    end
    return mattata.send_message(
        message,
        welcome_message,
        'markdown',
        true,
        false,
        nil,
        keyboard
    )
end

function administration.get_help_text(section)
    section = tostring(section)
    if not section or section == nil then
        return false
    elseif section == 'rules' then
        return [[Ensure people behave in your group by setting rules. You can do this using the <code>/setrules</code> command, passing the rules you'd like to set as an argument. These rules can be formatted in Markdown. If you'd like to modify the rules, just repeat the same process, thus overwriting the current rules. To display the group rules, you need to use the <code>/rules</code> command. Only group administrators and moderators can use the <code>/setrules</code> command.]]
    elseif section == 'welcome_message' then
        return [[Enhance the experience your group provides to its users by settings a custom welcome message. This can be done by using the <code>/setwelcome</code> command, passing the welcome message you'd like to set as an argument. This welcome message can be formatted in Markdown. You can use a few placeholders too, to personalise each welcome message. <code>$chat_id</code> will be replaced with the chat's numerical ID, <code>$user_id</code> will be replaced with the newly-joined user's numerical ID, <code>$name</code> will be replaced with the newly-joined user's name, and <code>$title</code> will be replaced with the chat title.]]
    elseif section == 'antispam' then
        return [[Rid of spammers with little effort by using my inbuilt anti-spam plugin. This is disabled by default. It can be turned on and customised using the <code>/antispam</code> command.]]
    elseif section == 'moderation' then
        return [[Want to promote users but don't feel comfortable with them being able to delete messages or report people for spam? Not to worry, you can allow people to use my administration commands (such as <code>/ban</code> and <code>/kick</code> by replying to one of their messages with the command <code>/mod</code>. If things just aren't working out then you can demote the user by replying to one of their messages with <code>/demod</code>.]]
    elseif section == 'administration' then
        return [[There are 4 main parts to the <i>actual</i> administration part of my functionality. These can be used by all group administrators and moderators. <code>/ban</code>, <code>/kick</code>, <code>/unban</code>, and <code>/warn</code>. <code>/kick</code> and <code>/ban</code> remove the targeted user from the chat. The only difference is that <code>/kick</code> will automatically unban the user after removing them, thus acting as a soft-ban. <code>/unban</code> will unban the targeted user from the chat, and <code>/warn</code> will warn the targeted user. A user will be banned after 3 warnings. <code>/kick</code>, <code>/ban</code>, and <code>/unban</code> can be used in reply to a user, or you can specify the user as an argument via their numerical ID or username (with or without a preceding <code>@</code>).]]
    elseif section == 'back' then
        return [[Learn more about using mattata for administrating your group by navigating using the buttons below:]]
    end
    return false
end

function administration.get_help_keyboard(chat_id)
    return {
        ['inline_keyboard'] = {
            {
                {
                    ['text'] = 'Rules',
                    ['callback_data'] = 'administration:ahelp:rules'
                },
                {
                    ['text'] = 'Welcome Message',
                    ['callback_data'] = 'administration:ahelp:welcome_message'
                }
            },
            {
                {
                    ['text'] = 'Anti-Spam',
                    ['callback_data'] = 'administration:ahelp:antispam'
                },
                {
                    ['text'] = 'Moderation',
                    ['callback_data'] = 'administration:ahelp:moderation'
                }
            },
            {
                {
                    ['text'] = 'Administration',
                    ['callback_data'] = 'administration:ahelp:administration'
                }
            },
            {
                {
                    ['text'] = 'Back',
                    ['callback_data'] = 'administration:back:' .. chat_id
                }
            }
        }
    }
end

function administration.on_help_callback_query(callback_query, message)
    local output = administration.get_help_text(callback_query.data:match('^ahelp:(.-)$'))
    if not output then
        return
    end
    local keyboard = administration.get_help_keyboard()
    mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        'html',
        true,
        json.encode(keyboard)
    )
end

function administration.report(message, bot_id)
    if not message.reply then
        return
    elseif message.reply.from.id == message.from.id then
        return
    end
    local admin_list = {}
    local admins = mattata.get_chat_administrators(message.chat.id)
    local notified = 0
    for n in pairs(admins.result) do
        if admins.result[n].user.id ~= bot_id then
            local output = '<b>' .. mattata.escape_html(message.from.first_name) .. ' needs help in ' .. mattata.escape_html(message.chat.title) .. '!</b>'
            if message.chat.username then
                output = output .. '\n<a href="https://t.me/' .. message.chat.username .. '/' .. message.reply.message_id .. '">Click here to view the reported message.</a>'
            end
            local success = mattata.send_message(
                admins.result[n].user.id,
                output,
                'html'
            )
            if success then
                mattata.forward_message(
                    admins.result[n].user.id,
                    message.chat.id,
                    false,
                    message.reply.message_id
                )
            end
            notified = notified + 1
        end
    end
    local output = 'I\'ve successfully reported that message to ' .. notified .. ' admin'
    if notified ~= 1 then
        output = output .. 's'
    end
    return mattata.send_message(
        message,
        output .. '!'
    )
end

function administration.format_admin_list(output, chat_id)
    local creator = ''
    local admin_count = 1
    local admins = ''
    for i, admin in pairs(output.result) do
        local user
        local branch = ' ├ '
        if admin.status == 'creator' then
            creator = mattata.escape_html(admin.user.first_name)
            if admin.user.username then
                creator = string.format(
                    '<a href="https://t.me/%s">%s</a>',
                    admin.user.username,
                    creator
                )
            end
        elseif admin.status == 'administrator' then
            user = mattata.escape_html(admin.user.first_name)
            if admin.user.username then
                user = string.format(
                    '<a href="https://t.me/%s">%s</a>',
                    admin.user.username,
                    user
                )
            end
            admin_count = admin_count + 1
            if admin_count == #output.result then
                branch = ' └ '
            end
            admins = admins .. branch .. user .. '\n'
        end
    end
    local mod_list = redis:smembers('administration:' .. chat_id .. ':mods')
    local mod_count = 0
    local mods = ''
    if next(mod_list) then
        local branch = ' ├ '
        local user
        for i = 1, #mod_list do
            user = mattata.get_linked_name(mod_list[i])
            if user then
                if i == #mod_list then
                    branch = ' └ '
                end
                mods = mods .. branch .. user .. '\n'
                mod_count = mod_count + 1
            end
        end
    end
    if creator == '' then
        creator = '-'
    end
    if admins == '' then
        admins = '-'
    end
    if mods == '' then
        mods = '-'
    end
    return string.format(
        '<b>👤 Creator</b>\n└ %s\n\n<b>👥 Admins</b> (%d)\n%s\n<b>👥 Moderators</b> (%d)\n%s',
        creator,
        admin_count - 1,
        admins,
        mod_count,
        mods
    )
end

function administration.admins(message)
    local success = mattata.get_chat_administrators(message.chat.id)
    if not success then
        return mattata.send_reply(
            message,
            'I couldn\'t get a list of administrators in this chat.'
        )
    end
    return mattata.send_message(
        message,
        administration.format_admin_list(success, message.chat.id),
        'html'
    )
end

function administration.link(message)
    local hash = mattata.get_redis_hash(
        message,
        'link'
    )
    local link = redis:hget(
        hash,
        'link'
    )
    if not link or link == 'false' then
        return mattata.send_reply(
            message,
            'There isn\'t a link set for this group.'
        )
    end
    return mattata.send_message(
        message,
        '<a href="' .. link .. '">' .. mattata.escape_html(message.chat.title) .. '</a>',
        'html'
    )
end

function administration.set_rules(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please specify the rules for ' .. message.chat.title .. '. Markdown formatting is supported.'
        )
    end
    local hash = mattata.get_redis_hash(
        message,
        'rules'
    )
    print(hash)
    redis:hset(
        hash,
        'rules',
        input
    )
    local success = mattata.send_message(
        message,
        input,
        'markdown'
    )
    if not success then
        return mattata.send_reply(
            message,
            'Invalid Markdown formatting.'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        success.result.message_id,
        'Successfully set the new rules!'
    )
end

function administration.get_rules(chat_id)
    if type(chat_id) == 'table' then
        chat_id = tostring(chat_id.chat.id)
    end
    local rules = redis:hget(
        'chat:' .. chat_id .. ':rules',
        'rules'
    )
    local resolved = mattata.get_chat(chat_id)
    if not resolved then
        return
    end
    if not rules then
        rules = 'There are no rules set for ' .. resolved.result.title .. '!'
    end
    return rules
end

function administration.rules(message, username)
    local rules = administration.get_rules(message)
    local success = mattata.send_message(
        message.from.id,
        rules,
        'markdown',
        true,
        false
    )
    local output
    if not success then
        output = 'You need to speak to me in private chat before I can send you the rules! Just click [here](https://telegram.me/' .. username .. '), press the "START" button, and try again!'
    else
        output = 'I have sent you the rules via private chat!'
    end
    return mattata.send_reply(
        message,
        output,
        'markdown'
    )
end

function administration.set_link(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please specify a URL to set as the group link.'
        )
    end
    local output
    if message.entities[2] and message.entities[2].type == 'url' and message.entities[2].offset == message.entities[1].offset + message.entities[1].length + 1 and message.entities[2].length == input:len() then -- Checks to ensure that only a URL was sent as an argument.
        local hash = mattata.get_redis_hash(
            message,
            'link'
        )
        redis:hset(
            hash,
            'link',
            input
        )
        output = '<a href="' .. input .. '">' .. mattata.escape_html(message.chat.title) .. '</a>'
    else
        output = 'That\'s not a valid url.'
    end
    local success = mattata.send_message(
        message,
        output,
        'html'
    )
    if not success then
        return mattata.send_reply(
            message,
            'That\'s not a valid url.'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        success.result.message_id,
        'Link set successfully!'
    )
end

function administration.whitelist_links(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please specify the URLs or @usernames you\'d like to whitelist.'
        )
    end
    local output = administration.check_links(
        message,
        'whitelist'
    )
    return mattata.send_reply(
        message,
        output
    )
end

function administration:on_message(message, configuration)
    if message.chat.type == 'private' then
        local input = mattata.input(message.text)
        if input then
            if tonumber(input) == nil and not input:match('^%@') then
                input = '@' .. input
            end
            local resolved = mattata.get_chat(input)
            if resolved and mattata.is_group_admin(
                resolved.result.id,
                message.from.id
            ) then
                message.chat = resolved.result
            elseif resolved then
                return mattata.send_reply(
                    message,
                    'That\'s not a valid chat!'
                )
            else
                return mattata.send_reply(
                    message,
                    'You don\'t appear to be an administrator in that chat!'
                )
            end
        else
            return mattata.send_reply(
                message,
                'My administrative functionality can only be used in groups/channels! If you\'re looking for help with using my administrative functionality, check out the "Administration" section of /help! Alternatively, if you wish to manage the settings for a group you administrate, you can do so here by using the syntax /administration <chat>.'
            )
        end
    end
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        if message.text:match('^[/!#]admins') or message.text:match('^[/!#]staff') then
            return administration.admins(message)
        elseif message.text:match('^[/!#]link') then
            return administration.link(message)
        elseif message.text:match('^[/!#]rules') then
            return administration.rules(
                message,
                self.info.username:lower()
            )
        elseif message.text:match('^[/!#]ops') or message.text:match('^[/!#]report') then
            return administration.report(
                message,
                self.info.id
            )
        elseif message.text:match('^[/!#]chats') or message.text:match('^[/!#]groups') then
            return administration.get_chats(message)
        end
        return -- Ignore all other requests from users who aren't administrators in the group.
    elseif message.text:match('^[/!#]mod') or message.text:match('^[/!#]promote') then
        return administration.mod(message)
    elseif message.text:match('^[/!#]demod') or message.text:match('^[/!#]demote') then
        return administration.demod(message)
    elseif message.text:match('^[/!#]links') or message.text:match('^[/!#]whitelistlink') then
        return administration.whitelist_links(message)
    elseif message.text:match('^[/!#]whitelist') then
        return administration.whitelist(
            message,
            self.info
        )
    elseif message.text:match('^[/!#]setlink') then
        return administration.set_link(message)
    elseif message.text:match('^[/!#]antispam') or message.text:match('^[/!#]administration') then
        local keyboard = administration.get_initial_keyboard(message.chat.id)
        local success = mattata.send_message(
            message.from.id,
            string.format(
                'Use the keyboard below to adjust the administration settings for <b>%s</b>:',
                mattata.escape_html(message.chat.title)
            ),
            'html',
            true,
            false,
            nil,
            json.encode(keyboard)
        )
        if not success then
            return mattata.send_reply(
                message,
                'Please send me a [private message](https://t.me/' .. self.info.username:lower() .. '), so that I can send you this information.',
                'markdown'
            )
        end
        return mattata.send_reply(
            message,
            'I have sent you the information you requested via private chat.'
        )
    elseif message.text:match('^[/%!%$]admins') or message.text:match('^[/!#]staff') then
        return administration.admins(message)
    elseif message.text:match('^[/!#]link') then
        return administration.link(message)
    elseif message.text:match('^[/!#]setrules') then
        return administration.set_rules(message)
    elseif message.text:match('^[/!#]rules') then
        return administration.rules(
            message,
            self.info.username:lower()
        )
    elseif message.text:match('^[/!#]pin') then
        return administration.pin(message)
    elseif message.text:match('^[/!#]ops') or message.text:match('^[/!#]report') then
        return administration.report(
            message,
            self.info.id
        )
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[/!#]chats del .-$') or message.text:match('^[/!#]groups del .-$') then
        return administration.del_chat(message)
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[/!#]chats new .-$') or message.text:match('^[/!#]groups new .-$') then
        return administration.new_chat(message)
    elseif message.text:match('^[/!#]chats') or message.text:match('^[/!#]groups') then
        return administration.get_chats(message)
    elseif message.text:match('^[/!#]tempban') then
        return administration.tempban(message)
    end
    return
end

function administration:cron()
    local tempbanned = redis:hgetall('tempbanned')
    if not next(tempbanned) then
        return
    end
    for k, v in pairs(tempbanned) do
        if os.time() > tonumber(k) then
            local chat_id, user_id = v:match('^(%-%d+):(%d+)$')
            local user = mattata.get_chat(user_id)
            local chat = mattata.get_chat(chat_id)
            local success = mattata.unban_chat_member(
                chat_id,
                user_id
            )
            redis:hdel(
                'tempbanned',
                k
            )
            redis:srem(
                string.format(
                    'chat:%s:tempbanned',
                    chat_id
                ),
                user_id
            )
            local unban_status = '\nI have unbanned them from this chat.'
            if not success then
                unban_status = '\nI was unable to unban them from this chat.'
            end
            if user then
                mattata.send_message(
                    chat_id,
                    string.format(
                        '%s\'s <code>[%s]</code> temp-ban has expired.%s',
                        mattata.escape_html(user.result.first_name),
                        user.result.id,
                        unban_status
                    ),
                    'html'
                )
            end
            if chat then
                if success then
                    mattata.send_message(
                        user_id,
                        string.format(
                            'Your temp-ban from %s <code>[%s]</code> has expired, you are now allowed to join again!',
                            mattata.escape_html(chat.result.title),
                            chat.result.id
                        ),
                        'html'
                    )
                else
                    mattata.send_message(
                        user_id,
                        string.format(
                            'Your temp-ban from %s <code>[%s]</code> has expired - however, I was unable to unban you!',
                            mattata.escape_html(chat.result.title),
                            chat.result.id
                        ),
                        'html'
                    )
                end
            end
        end
    end
    return
end

return administration