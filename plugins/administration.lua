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
    :command('admins')
    :command('staff')
    :command('chats')
    :command('links')
    :command('whitelistlink')
    :command('link')
    :command('rules')
    :command('pin')
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
    then
        return false
    elseif not redis:hexists(
        'chat:' .. chat_id .. ':settings',
        tostring(setting)
    )
    then
        return false
    end
    return true
end

function administration.toggle_setting(chat_id, setting, value)
    value = tostring(value) ~= 'nil'
    and value
    or true
    if not chat_id
    or not setting
    then
        return false
    elseif not redis:hexists(
        'chat:' .. chat_id .. ':settings',
        tostring(setting)
    )
    then
        return redis:hset(
            'chat:' .. chat_id .. ':settings',
            tostring(setting),
            value
        )
    end
    return redis:hdel(
        'chat:' .. chat_id .. ':settings',
        tostring(setting)
    )
end

function administration.get_initial_keyboard(chat_id)
   if not administration.get_setting(
       chat_id,
       'use administration'
    )
    then
        return mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
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
            'antispam:' .. chat_id
        )
        :callback_data_button(
            'Warning Settings',
            'administration:' .. chat_id .. ':warnings'
        )
    )
    :row(
        mattata.row():callback_data_button(
            'Vote-Ban Settings',
            'administration:' .. chat_id .. ':voteban'
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
            'Send Misc Responses?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'misc responses'
            )
            and utf8.char(10060)
            or utf8.char(9989),
            'administration:' .. chat_id .. ':misc_responses'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Shared AI Conversation?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'shared ai'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':shared_ai'
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Force Group Language?',
            'administration:nil'
        )
        :callback_data_button(
            administration.get_setting(
                chat_id,
                'force group language'
            )
            and utf8.char(9989)
            or utf8.char(10060),
            'administration:' .. chat_id .. ':force_group_language'
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

function administration.get_voteban_keyboard(chat_id)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current_required_upvotes = redis:hget(
        string.format(
            'chat:%s:settings',
            chat_id
        ),
        'required upvotes for vote bans'
    ) or 5
    print(current_required_upvotes)
    local current_required_downvotes = redis:hget(
        string.format(
            'chat:%s:settings',
            chat_id
        ),
        'required downvotes for vote bans'
    ) or 5
    print(current_required_downvotes)
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Upvotes needed to ban:',
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':voteban_upvotes:' .. tonumber(current_required_upvotes) - 1,
        tostring(current_required_upvotes),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':voteban_upvotes:' .. tonumber(current_required_upvotes) + 1
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Downvotes needed to dismiss:',
                ['callback_data'] = 'administration:nil'
            }
        }
    )
    administration.insert_keyboard_row(
        keyboard,
        '-',
        'administration:' .. chat_id .. ':voteban_downvotes:' .. tonumber(current_required_downvotes) - 1,
        tostring(current_required_downvotes),
        'administration:nil',
        '+',
        'administration:' .. chat_id .. ':voteban_downvotes:' .. tonumber(current_required_downvotes) + 1
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

function administration.get_hash_status(chat_id, hash_type)
    if redis:get('administration:' .. chat_id .. ':' .. hash_type)
    then
        return true
    end
    return false
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
    if callback_query.data:match('^%-%d+:voteban$')
    then
        keyboard = administration.get_voteban_keyboard(
            callback_query.data:match('^(%-%d+):voteban$')
        )
    elseif callback_query.data:match('^%-%d+:voteban_upvotes:.-$')
    then
        local chat_id, required_upvotes = callback_query.data:match('^(%-%d+):voteban_upvotes:(.-)$')
        if tonumber(required_upvotes) < configuration.voteban.upvotes.minimum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum number of upvotes required for a vote-ban is 2.'
            )
        elseif tonumber(required_upvotes) > configuration.voteban.upvotes.maximum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum number of upvotes required for a vote-ban is 20.'
            )
        elseif tonumber(required_upvotes) == nil
        then
            return
        end
        redis:hset(
            'chat:' .. chat_id .. ':settings',
            'required upvotes for vote bans',
            tonumber(required_upvotes)
        )
        keyboard = administration.get_voteban_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:voteban_downvotes:.-$')
    then
        local chat_id, required_downvotes = callback_query.data:match('^(%-%d+):voteban_downvotes:(.-)$')
        if tonumber(required_downvotes) < configuration.voteban.downvotes.minimum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum number of downvotes required for a vote-ban is 2.'
            )
        elseif tonumber(required_downvotes) > configuration.voteban.downvotes.maximum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum number of downvotes required for a vote-ban is 20.'
            )
        elseif tonumber(required_downvotes) == nil
        then
            return
        end
        redis:hset(
            'chat:' .. chat_id .. ':settings',
            'required downvotes for vote bans',
            tonumber(required_downvotes)
        )
        keyboard = administration.get_voteban_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:warnings$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):warnings$')
        keyboard = administration.get_warnings(chat_id)
    elseif callback_query.data:match('^%-%d+:max_warnings:.-$')
    then
        local chat_id, max_warnings = callback_query.data:match('^(%-%d+):max_warnings:(.-)$')
        if tonumber(max_warnings) > configuration.administration.warnings.maximum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum number of warnings is 10.'
            )
        elseif tonumber(max_warnings) < configuration.administration.warnings.minimum
        then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum number of warnings is 2.'
            )
        elseif tonumber(max_warnings) == nil
        then
            return
        end
        redis:hset(
            'chat:' .. chat_id .. ':values',
            'max warnings',
            tonumber(max_warnings)
        )
        keyboard = administration.get_warnings(chat_id)
    elseif callback_query.data:match('^%-%d+:toggle$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):toggle$')
        administration.toggle_setting(
            chat_id,
            'use administration'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:rtl$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):rtl$')
        administration.toggle_setting(
            chat_id,
            'anti-rtl'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:rules$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):rules$')
        administration.toggle_setting(
            chat_id,
            'rules on join'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:inactive$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):inactive$')
        administration.toggle_setting(
            chat_id,
            'remove inactive users'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:action$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):action$')
        administration.toggle_setting(
            chat_id,
            'ban not kick'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:antibot$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):antibot$')
        administration.toggle_setting(
            chat_id,
            'antibot'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:antilink$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):antilink$')
        administration.toggle_setting(
            chat_id,
            'antilink'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:antispam$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):antispam$')
        administration.toggle_setting(
            chat_id,
            'anti-spam'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:welcome_message$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):welcome_message$')
        administration.toggle_setting(
            chat_id,
            'welcome message'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:delete_commands$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):delete_commands$')
        administration.toggle_setting(
            chat_id,
            'delete commands'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:misc_responses$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):misc_responses$')
        administration.toggle_setting(
            chat_id,
            'misc responses'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:shared_ai$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):shared_ai$')
        administration.toggle_setting(
            chat_id,
            'shared ai'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:force_group_language$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):force_group_language$')
        administration.toggle_setting(
            chat_id,
            'force group language'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:log$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):log$')
        administration.toggle_setting(
            chat_id,
            'log administrative actions'
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:enable_admins_only$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):enable_admins_only$')
        redis:set(
            string.format(
                'administration:%s:admins_only',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:disable_admins_only$')
    then
        local chat_id = callback_query.data:match('^(%-%d+):disable_admins_only$')
        redis:del('administration:' .. chat_id .. ':admins_only')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+:ahelp$')
    then
        keyboard = administration.get_help_keyboard(callback_query.data:match('^(%-%d+):ahelp$'))
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration.get_help_text('back'),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^%-%d+:ahelp:.-$')
    then
        return administration.on_help_callback_query(
            callback_query,
            callback_query.data:match('^%-%d+:ahelp:.-$')
        )
    elseif callback_query.data:match('^%-%d+:back$')
    then
        keyboard = administration.get_initial_keyboard(callback_query.data:match('^(%-%d+):back$'))
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'dismiss_disabled_message'
    then
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
    local link = redis:hget(
        'chat:' .. message.chat.id .. ':values',
        'link'
    )
    if not link
    then
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

function administration.get_rules(chat_id)
    if type(chat_id) == 'table' then
        chat_id = tostring(chat_id.chat.id)
    end
    local rules = redis:hget(
        'chat:' .. chat_id .. ':values',
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
        end
        return -- Ignore all other requests from users who aren't administrators in the group.
    elseif message.text:match('^[/!#]links') or message.text:match('^[/!#]whitelistlink') then
        return administration.whitelist_links(message)
    elseif message.text:match('^[/!#]whitelist') then
        return administration.whitelist(
            message,
            self.info
        )
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
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[/!#]chats del .-$') then
        return administration.del_chat(message)
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[/!#]chats new .-$') then
        return administration.new_chat(message)
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