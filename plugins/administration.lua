--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local administration = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function administration:init(configuration)
    administration.arguments = 'administration'
    administration.commands = mattata.commands(
        configuration.info.username,
        configuration.command_prefix
    ):command('administration')
     :command('antispam')
     :command('mod')
     :command('promote')
     :command('demod')
     :command('demote')
     :command('setwelcome')
     :command('blacklist')
     :command('whitelist')
     :command('kick')
     :command('ban')
     :command('unban')
     :command('warn')
     :command('admins')
     :command('staff')
     :command('groups')
     :command('chats')
     :command('link')
     :command('setlink')
     :command('custom')
     :command('rules')
     :command('setrules')
     :command('pin')
     :command('report')
     :command('ops').table
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

function administration.get_initial_keyboard(message)
    local current_status, new_status
    if redis:get('administration:' .. message.chat.id .. ':enabled') then
        current_status = 'Disable Administration'
        new_status = 'administration:disable'
    else
        current_status = 'Enable Administration'
        new_status = 'administration:enable'
    end
    local keyboard = {
        ['inline_keyboard'] = {
            {
                {
                    ['text'] = current_status,
                    ['callback_data'] = new_status
                }
            }
        }
    }
    if current_status ~= 'Disable Administration' then
        return keyboard
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Anti-Spam Settings',
                ['callback_data'] = 'administration:anti_spam'
            }
        }
    )
    local arabic_status = administration.get_hash_status(
        message.chat.id,
        'rtl'
    )
    local arabic_status_text = 'Forbidden'
    local new_arabic_status = 'disable_rtl'
    if not arabic_status then
        arabic_status_text = 'Allowed'
        new_arabic_status = 'enable_rtl'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Arabic/RTL',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = arabic_status_text,
                ['callback_data'] = 'administration:' .. new_arabic_status
            }
        }
    )
    local antibot_status = administration.get_hash_status(
        message.chat.id,
        'antibot'
    )
    local antibot_status_text = 'Enabled'
    local new_antibot_status = 'disable_antibot'
    if not antibot_status then
        antibot_status_text = 'Disabled'
        new_antibot_status = 'enable_antibot'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Anti-Bot',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = antibot_status_text,
                ['callback_data'] = 'administration:' .. new_antibot_status
            }
        }
    )
    local admins_only_status = administration.get_hash_status(
        message.chat.id,
        'admins_only'
    )
    local admins_only_status_text = 'Enabled'
    local new_admins_only_status = 'disable_admins_only'
    if not admins_only_status then
        admins_only_status_text = 'Disabled'
        new_admins_only_status = 'enable_admins_only'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Admins-Only Mode',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = admins_only_status_text,
                ['callback_data'] = 'administration:' .. new_admins_only_status
            }
        }
    )
    local welcome_status = administration.get_hash_status(
        message.chat.id,
        'welcome'
    )
    local welcome_status_text = 'On'
    local new_welcome_status = 'disable_welcome'
    if not welcome_status then
        welcome_status_text = 'Off'
        new_welcome_status = 'enable_welcome'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Welcome Message',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = welcome_status_text,
                ['callback_data'] = 'administration:' .. new_welcome_status
            }
        }
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Administration Help',
                ['callback_data'] = 'administration:ahelp'
            }
        }
    )
    return keyboard
end

function administration.get_anti_spam_keyboard(message)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current = administration.get_message_limit(
        message,
        'text'
    )
    local lower = tonumber(current) - 1
    local higher = tonumber(current) + 1
    local forwarded_current = administration.get_message_limit(
        message,
        'forwarded'
    )
    local forwarded_lower = tonumber(forwarded_current) - 1
    local forwarded_higher = tonumber(forwarded_current) + 1
    local stickers_current = administration.get_message_limit(
        message,
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
        'administration:limit:text:' .. lower,
        tostring(current),
        'administration:nil',
        '+',
        'administration:limit:text:' .. higher
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
        'administration:limit:forwarded:' .. forwarded_lower,
        tostring(forwarded_current),
        'administration:nil',
        '+',
        'administration:limit:forwarded:' .. forwarded_higher
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
        'administration:limit:stickers:' .. stickers_lower,
        tostring(stickers_current),
        'administration:nil',
        '+',
        'administration:limit:stickers:' .. stickers_higher
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Back',
                ['callback_data'] = 'administration:back'
            }
        }
    )
    return keyboard
end

function administration.get_message_limit(message, spam_type)
    local hash = mattata.get_redis_hash(
        message,
        'administration'
    )
    local limit = redis:hget(
        hash,
        spam_type
    )
    if not limit or limit == 'false' or tonumber(limit) == nil then
        if spam_type == 'text' then
            return 8
        elseif spam_type == 'forwarded' then
            return 16
        elseif spam_type == 'stickers' then
            return 4
        end
    end
    return tonumber(limit)
end

function administration.get_hash_status(chat_id, hash_type)
    if redis:get('administration:' .. chat_id .. ':' .. hash_type) then
        return true
    end
    return false
end

function administration.is_user_spamming(message) -- Checks if a user is spamming and return two boolean values
    local messages = redis:get('administration:text:' .. message.chat.id .. ':' .. message.from.id)
    local forwarded = redis:get('administration:forwarded:' .. message.chat.id .. ':' .. message.from.id)
    local stickers = redis:get('administration:stickers:' .. message.chat.id .. ':' .. message.from.id)
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
    if message.forward_from or message.forward_from_chat then
        if tonumber(forwarded) == nil then
            forwarded = 1
        end
        redis:setex(
            'administration:forwarded:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(forwarded) + 1
        )
        if tonumber(forwarded) == tonumber(forwarded_limit) then
            return true, 'forwarded messages'
        end
    elseif message.text and not message.is_media then
        if tonumber(messages) == nil then
            messages = 1
        end
        redis:setex(
            'administration:text:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(messages) + 1
        )
        if tonumber(messages) == tonumber(limit) then
            return true, 'text messages'
        end
    elseif message.sticker then
        if tonumber(stickers) == nil then
            stickers = 1
        end
        redis:setex(
            'administration:stickers:' .. message.chat.id .. ':' .. message.from.id,
            5,
            tonumber(stickers) + 1
        )
        if tonumber(stickers) == tonumber(stickers_limit) then
            return true, 'stickers'
        end
    end
    if administration.get_hash_status(
        message.chat.id,
        'rtl'
    ) and message.text:match('[\216-\219][\128-\191]') then -- Match Arabic and RTL characters.
        return true, 'Arabic/RTL characters'
    end
    return false, nil
end

function administration.blacklist(message)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to blacklist, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                'I can\'t blacklist that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == configuration.info.id then
            return
        end
        local user = message.reply_to_message.from.id
        local hash = 'group_blacklist:' .. message.chat.id .. ':' .. user
        redis:set(
            hash,
            true
        )
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has blacklisted ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from using ' .. configuration.info.username .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message,
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                'That\'s a ' .. resolved.result.type .. ', not a user!'
            )
        end
        if mattata.is_group_admin(
            message.chat.id,
            resolved.result.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t blacklist that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == configuration.info.id then
            return
        end
        local user = resolved.result.id
        redis:set(
            'group_blacklist:' .. message.chat.id .. ':' .. user,
            true
        )
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has blacklisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from using ' .. configuration.info.first_name .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

function administration.whitelist(message)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to whitelist, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(
            message.chat.id,
            message.reply_to_message.from.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t whitelist that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == configuration.info.id then
            return
        end
        local user = message.reply_to_message.from.id
        local hash = 'group_blacklist:' .. message.chat.id .. ':' .. user
        redis:del(hash)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] to use ' .. configuration.info.username .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message,
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                'That\'s a ' .. resolved.result.type .. ', not a user!'
            )
        end
        if mattata.is_group_admin(
            message.chat.id,
            resolved.result.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t whitelist that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == configuration.info.id then
            return
        end
        local user = resolved.result.id
        local hash = 'group_blacklist:' .. message.chat.id .. ':' .. user
        redis:del(hash)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] to use ' .. configuration.info.first_name .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

function administration.new_chat(message)
    local link, title = message.text:match('^%/chats new (.-) (.-)$')
    if not link or not title then
        return
    elseif not link:match('https%:%/%/t%.me%/(.-)$') then
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
        end
        if not json.decode(v).link or not json.decode(v).title then
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
    local title = message.text:match('^%/chats del (.-)$')
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
    local output = {}
    for k, v in pairs(redis:smembers('mattata:configuration:chats')) do
        if v and json.decode(v).link and json.decode(v).title then
            local link, title = json.decode(v).link, json.decode(v).title
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
    return mattata.send_message(
        message.chat.id,
        table.concat(
            output,
            '\n'
        ),
        'html'
    )
end

function administration.kick(message)
    local input = mattata.input(message.text)
    if message.chat.type ~= 'supergroup' or not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to kick, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(
            message.chat.id,
            message.reply_to_message.from.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t kick that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == configuration.info.id then
            return
        end
        local kick = mattata.kick_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if kick then
            message.text = message.text:gsub('^%/kick', '/unban')
            administration.unban(message, true)
        else
            return mattata.send_reply(message, 'I couldn\'t kick ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.')
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has kicked ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message,
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                'That\'s a ' .. resolved.result.type .. ', not a user!'
            )
        end
        if mattata.is_group_admin(
            message.chat.id,
            resolved.result.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t kick that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == configuration.info.id then
            return
        end
        local user = resolved.result.id
        local kick = mattata.kick_chat_member(
            message.chat.id,
            user
        )
        local unban = mattata.unban_chat_member(
            message.chat.id,
            user
        )
        if not kick then
            return mattata.send_reply(
                message,
                'I couldn\'t kick ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        elseif not unban then
            return mattata.send_reply(
                message,
                'I couldn\'t unban ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has kicked ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

function administration.ban(message)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator of this chat to use this command.'
        )
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to ban, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                'I can\'t ban that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == configuration.info.id then
            return
        end
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has banned ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message, 
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                input .. ' is a ' .. resolved.result.type .. ', not a user!'
            )
        elseif mattata.is_group_admin(message.chat.id, resolved.result.id) then
            return mattata.send_reply(
                message,
                'I can\'t ban that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == configuration.info.id then
            return
        end
        local success = mattata.kick_chat_member(
            message.chat.id,
            resolved.result.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has banned ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

function administration.unban(message, is_silent)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator of this chat to use this command.'
        )
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to unban, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                'I can\'t unban that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == configuration.info.id then
            return
        end
        local success = mattata.unban_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t unban ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if not is_silent then
            if configuration.log_admin_actions and configuration.log_channel ~= '' then
                mattata.send_message(
                    configuration.log_channel,
                    '<pre>' .. mattata.escape_html(output) .. '</pre>',
                    'html'
                )
            end
            return mattata.send_message(
                message.chat.id,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message, 
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                input .. ' is a ' .. resolved.result.type .. ', not a user!'
            )
        elseif mattata.is_group_admin(message.chat.id, resolved.result.id) then
            return mattata.send_reply(
                message,
                'I can\'t unban that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == configuration.info.id then
            return
        end
        local success = mattata.kick_chat_member(
            message.chat.id,
            resolved.result.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t unban ' .. resolved.result.first_name .. ' because they\'re either not banned in this chat, or I\'m not an administrator.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
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
    elseif not message.reply_to_message then
        return mattata.send_reply(
            message,
            'You must use this command via reply to the targeted user\'s message.'
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        message.reply_to_message.from.id
    ) then
        return mattata.send_reply(
            message,
            'The targeted user is an administrator in this chat.'
        )
    end
    local name = message.reply_to_message.from.first_name
    local hash = 'chat:' .. message.chat.id .. ':warnings'
    local amount = redis:hincrby(
        hash,
        message.reply_to_message.from.id,
        1
    )
    local maximum = 3
    local text, res
    amount, maximum = tonumber(amount), tonumber(maximum)
    if amount >= maximum then
        text = message.reply_to_message.from.first_name .. ' was banned for reaching the maximum number of allowed warnings (' .. maximum .. ').'
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban that user. Please ensure that I\'m an administrator and that the targeted user isn\'t.'
            )
        end
        redis:hdel(
            'chat:' .. message.chat.id .. ':warnings',
            message.reply_to_message.from.id
        )
        return mattata.send_message(
            message.chat.id,
            text
        )
    end
    local difference = maximum - amount
    text = '*%s* has been warned `[`%d/%d`]`'
    if message.text ~= configuration.command_prefix .. 'warn' then
        text = text .. '\n*Reason:* ' .. mattata.escape_markdown(message.text_lower:gsub('^/warn ', ''))
    end
    text = text:format(
        mattata.escape_markdown(name),
        amount,
        maximum
    )
    local keyboard = {
        ['inline_keyboard'] = {
            {
                {
                    ['text'] = 'Remove Warning',
                    ['callback_data'] = 'administration:warn:remove:' .. message.reply_to_message.from.id
                },
                {
                    ['text'] = 'Reset Warnings',
                    ['callback_data'] = 'administration:warn:reset:' .. message.reply_to_message.from.id
                }
            }
        }
    }
    return mattata.send_message(
        message.chat.id,
        text,
        'markdown',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

function administration:on_callback_query(callback_query, message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        callback_query.from.id
    ) then
        return
    end
    local keyboard
    if callback_query.data == 'anti_spam' then
        keyboard = administration.get_anti_spam_keyboard(message)
    elseif callback_query.data:match('^limit:(.-):(.-)$') then
        local spam_type, limit = callback_query.data:match('^limit:(.-):(.-)$')
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
            message,
            'administration'
        )
        redis:hset(
            hash,
            spam_type,
            tonumber(limit)
        )
        keyboard = administration.get_anti_spam_keyboard(message)
    elseif callback_query.data == 'enable' then
        redis:set(
            'administration:' .. message.chat.id .. ':enabled',
            true
        )
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'disable' then
        redis:del('administration:' .. message.chat.id .. ':enabled')
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'enable_rtl' then
        redis:set(
            'administration:' .. message.chat.id .. ':rtl',
            true
        )
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'disable_rtl' then
        redis:del('administration:' .. message.chat.id .. ':rtl')
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'enable_antibot' then
        redis:set(
            'administration:' .. message.chat.id .. ':antibot',
            true
        )
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'disable_antibot' then
        redis:del('administration:' .. message.chat.id .. ':antibot')
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'enable_welcome' then
        redis:set(
            'administration:' .. message.chat.id .. ':welcome',
            true
        )
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'disable_welcome' then
        redis:del('administration:' .. message.chat.id .. ':welcome')
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'enable_admins_only' then
        redis:set(
            'administration:' .. message.chat.id .. ':admins_only',
            true
        )
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'disable_admins_only' then
        redis:del('administration:' .. message.chat.id .. ':admins_only')
        keyboard = administration.get_initial_keyboard(message)
    elseif callback_query.data == 'ahelp' then
        keyboard = administration.get_help_keyboard()
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration.get_help_text('back'),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^ahelp%:(.-)$') then
        return administration.on_help_callback_query(callback_query, message)
    elseif callback_query.data == 'back' then
        keyboard = administration.get_initial_keyboard(message)
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                'Use the keyboard below to adjust the administration settings for <b>%s</b>:',
                mattata.escape_html(message.chat.title)
            ),
            'html',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^warn:reset:(.-)$') then
        redis:hdel(
            'chat:' .. message.chat.id .. ':warnings',
            callback_query.data:match('^warn:reset:(.-)$')
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Warnings reset by ' .. callback_query.from.first_name
        )
    elseif callback_query.data:match('^warn:remove:(.-)$') then
        local amount = redis:hincrby(
            'chat:' .. message.chat.id .. ':warnings',
            callback_query.data:match('^warn:remove:(.-)$'),
            -1
        )
        local text, maximum, difference
        if tonumber(amount) < 0 then
            text = 'The number of warnings received by this user is already zero!'
            redis:hincrby(
                'chat:' .. message.chat.id .. ':warnings',
                callback_query.data:match('^warn:remove:(.-)$'),
                1
            )
        else
            maximum = 3
            difference = tonumber(maximum) - tonumber(amount)
            text = string.format(
                'Warning removed! (%d/%d)',
                tonumber(amount),
                tonumber(maximum)
            )
        end
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            text
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
    local last_pin = redis:get('administration:' .. message.chat.id .. ':pin')
    local pin_exists = true
    if not input then
        if not last_pin then
            return mattata.send_reply(
                message,
                'You haven\'t set a pin before. Use /pin <text> to set one. Markdown formatting is supported.'
            )
        end
        local success = mattata.send_message(
            message.chat.id,
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
                'I found an existing pin, but the message I sent it in was deleted and I can\'t find it anymore. Set a new one with /pin <text>. Markdown formatting is supported.'
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
    if not success and redis:get('administration:' .. message.chat.id .. ':pin') then
        mattata.send_reply(
            message,
            'There was an error whilst updating your pin. Either the text you entered contained invalid Markdown syntax, or the pin has been deleted. I\'m now going to try and send you a new pin, which you\'ll be able to find below - if you need to modify it then make sure the message still exists, and use /pin <text>.'
        )
    elseif not success then
        local new_pin = mattata.send_message(
            message.chat.id,
            input,
            'markdown',
            true,
            false
        )
        if not new_pin then
            return mattata.send_reply(
                message,
                'I couldn\'t send that text because it contains invalid Markdown syntax.'
            )
        end
        redis:set(
            'administration:' .. message.chat.id .. ':pin',
            tostring(new_pin.result.message_id)
        )
        last_pin = tostring(new_pin.result.message_id)
    end
    return mattata.send_message(
        message.chat.id,
        'Click here to see the pin, updated to contain the text you gave me.',
        nil,
        true,
        false,
        last_pin
    )
end

function administration:process_message(message, configuration)
    if mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and not mattata.is_global_admin(message.from.id) then -- Don't iterate over the user's messages if they're an administrator in the group.
        return
    end
    local is_spamming, media_type = administration.is_user_spamming(message)
    if not is_spamming then
        return
    end
    local success = mattata.kick_chat_member(
        message.chat.id,
        message.from.id
    )
    if not success then
        return
    end
    mattata.unban_chat_member(
        message.chat.id,
        message.from.id
    )
    local output = mattata.escape_html(configuration.info.first_name) .. ' [' .. configuration.info.id .. '] has kicked ' .. mattata.escape_html(message.from.first_name) .. ' [' .. message.from.id .. '] from ' .. mattata.escape_html(message.chat.title) .. ' [' .. message.chat.id .. '] for flooding the chat with ' .. media_type .. '.'
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
        mattata.send_message(
            configuration.log_channel,
            '<pre>' .. output .. '</pre>',
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. output .. '</pre>',
        'html'
    )
end

function administration.get_welcome_message(message)
    local hash = mattata.get_redis_hash(
        message,
        'welcome_message'
    )
    local welcome_message = redis:hget(
        hash,
        'welcome_message'
    )
    if not welcome_message or welcome_message == 'false' then
        return false
    else
        return welcome_message
    end
end

function administration:on_new_chat_member(message, configuration, language)
    if message.new_chat_member.id == configuration.info.id then
        return mattata.send_message(
            message.chat.id,
            'Thanks for adding me to ' .. message.chat.title .. ', ' .. message.from.first_name .. '! Additionally, if you want to enable my administration functionality, use ' .. configuration.command_prefix .. 'administration. To disable my AI functionality, use ' .. configuration.command_prefix .. 'plugins disable ai.'
        )
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) and redis:get('administration:' .. message.chat.id .. ':antibot') and message.new_chat_member.username and message.new_chat_member.username:lower():match('bot$') and message.new_chat_member.id ~= message.from.id then
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.new_chat_member.id
        )
        if success then
            local output = mattata.escape_html(configuration.info.first_name) .. ' [' .. configuration.info.id .. '] has kicked ' .. mattata.escape_html(message.new_chat_member.first_name) .. ' [' .. message.new_chat_member.id .. '] from ' .. mattata.escape_html(message.chat.title) .. ' [' .. message.chat.id .. '] because anti-bot is enabled.'
            if configuration.log_admin_actions and configuration.log_channel ~= '' then
                mattata.send_message(
                    configuration.log_channel,
                    '<pre>' .. output .. '</pre>',
                    'html'
                )
            end
            return mattata.send_message(
                message.chat.id,
                '<pre>' .. output .. '</pre>',
                'html'
            )
        end
    elseif not redis:get('administration:' .. message.chat.id .. ':welcome') then
        return
    end
    local welcome_message = administration.get_welcome_message(message)
    if not welcome_message then
        local join_messages = language.join_messages
        local name = message.new_chat_member.first_name:gsub('%%', '%%%%')
        local output = join_messages[math.random(#join_messages)]:gsub('NAME', name)
        return mattata.send_message(
            message.chat.id,
            output,
            nil,
            true,
            false,
            nil,
            json.encode(
                {
                    ['inline_keyboard'] = {
                        {
                            {
                                ['text'] = '📚 Group Rules',
                                ['url'] = string.format(
                                    'https://telegram.me/%s?start=%s:rules',
                                    configuration.info.username,
                                    message.chat.id
                                )
                            }
                        }
                    }
                }
            )
        )
    else
        local name = message.new_chat_member.first_name
        if message.new_chat_member.last_name then
            name = name .. ' ' .. message.new_chat_member.last_name
        end
        name = name:gsub('%%', '%%%%')
        name = mattata.escape_markdown(name)
        local title = message.chat.title:gsub('%%', '%%%%')
        title = mattata.escape_markdown(title)
        welcome_message = welcome_message:gsub('%$user_id', message.new_chat_member.id):gsub('%$chat_id', message.chat.id):gsub('%$name', name):gsub('%$title', title)
        return mattata.send_message(
            message.chat.id,
            welcome_message,
            'markdown',
            true,
            false,
            nil,
            json.encode(
                {
                    ['inline_keyboard'] = {
                        {
                            {
                                ['text'] = '📚 Group Rules',
                                ['url'] = string.format(
                                    'https://telegram.me/%s?start=%s:rules',
                                    configuration.info.username,
                                    message.chat.id
                                )
                            }
                        }
                    }
                }
            )
        )
    end
end

function administration.get_help_text(section)
    section = tostring(section)
    if not section or section == nil then
        return false
    elseif section == 'rules' then
        return [[Ensure people behave in your group by setting rules. You can do this using the <code>/setrules</code> command, passing the rules you'd like to set as an argument. These rules can be formatted in Markdown. If you'd like to modify the rules, just repeat the same process, thus overwriting the current rules. To display the group rules, you need to use the <code>/rules</code> command. Only group administrators and moderators can use the <code>/setrules</code> command.]]
    elseif section == 'welcome_message' then
        return [[Enhance the experience your group provides to its users by settings a custom welcome message. This can be done by using the <code>/setwelcome</code> command, passing the welcome message you'd like to set as an argument. This welcome message can be formatted in Markdown. You can use a few placeholders too, to personalise each welcome message. <code>$chat_id</code> will be replaced with the chat's numerical ID, <code>$user_id</code> will be replaced with the newly-joined user's numerical ID, <code>$name</code> will be replaced with the newly-joined user's name, and <code>$title</code> will be replaced with the chat title.]]
    elseif section == 'anti_spam' then
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

function administration.get_help_keyboard()
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
                    ['callback_data'] = 'administration:ahelp:anti_spam'
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
                    ['callback_data'] = 'administration:back'
                }
            }
        }
    }
end

function administration.on_help_callback_query(callback_query, message)
    local output = administration.get_help_text(callback_query.data:match('^ahelp%:(.-)$'))
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

function administration.report(message)
    if not message.reply_to_message then
        return
    elseif message.reply_to_message.from.id == message.from.id then
        return
    end
    local admin_list = {}
    local admins = mattata.get_chat_administrators(message.chat.id)
    local notified = 0
    for n in pairs(admins.result) do
        if admins.result[n].user.id ~= self.info.id then
            local output = '<b>' .. mattata.escape_html(message.from.first_name) .. ' needs help in ' .. mattata.escape_html(message.chat.title) .. '!</b>'
            if message.chat.username then
                output = output .. '\n<a href="https://t.me/' .. message.chat.username .. '/' .. message.reply_to_message.message_id .. '">Click here to view the reported message.</a>'
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
                    message.reply_to_message.message_id
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
        message.chat.id,
        output .. '!'
    )
end

function administration.mod(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    ) and not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            'You must send this message in reply to the user you\'d like to promote.'
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        message.reply_to_message.from.id,
        true
    ) then
        return mattata.send_reply(
            message,
            'This user cannot be promoted because they\'re an administrator in this chat.'
        )
    elseif mattata.is_group_mod(
        message.chat.id,
        message.reply_to_message.from.id
    ) then
        return mattata.send_reply(
            message,
            'This user cannot be promoted because they\'re already a moderator in this chat.'
        )
    end
    redis:sadd(
        'administration:' .. message.chat.id .. ':mods',
        message.reply_to_message.from.id
    )
    redis:set(
        'mods:' .. message.chat.id .. ':' .. message.reply_to_message.from.id,
        true
    )
    return mattata.send_reply(
        message,
        'This user is now a moderator in this chat. They have access to administrative commands such as ' .. configuration.command_prefix .. 'ban and ' .. configuration.command_prefix .. 'kick. To demote them, just reply to one of their messages with ' .. configuration.command_prefix .. 'demod.'
    )
end

function administration.demod(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    ) and not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            'You must send this message in reply to the user you\'d like to demote.'
        )
    elseif mattata.is_global_admin(message.reply_to_message.from.id) then
        return
    elseif mattata.is_group_admin(
        message.chat.id,
        message.reply_to_message.from.id,
        true
    ) then
        return mattata.send_reply(
            message,
            'This user cannot be demoted because they\'re an administrator in this chat.'
        )
    elseif not mattata.is_group_mod(
        message.chat.id,
        message.reply_to_message.from.id
    ) then
        return mattata.send_reply(
            message,
            'This user cannot be demoted because they\'re not a moderator in this chat.'
        )
    end
    redis:srem(
        'administration:' .. message.chat.id .. ':mods',
        message.reply_to_message.from.id
    )
    redis:del('mods:' .. message.chat.id .. ':' .. message.reply_to_message.from.id)
    return mattata.send_reply(
        message,
        'This user is no longer a moderator in this chat. They no longer have access to administrative commands such as ' .. configuration.command_prefix .. 'ban and ' .. configuration.command_prefix .. 'kick. To promote them again, just reply to one of their messages with ' .. configuration.command_prefix .. 'mod.'
    )
end

function administration.groups(message)
    local input = mattata.input(message.text)
    local groups = {}
    local results = {}
    for k, v in pairs(configuration.groups) do
        if v then
            local result = '• <a href="' .. v .. '">' .. mattata.escape_html(k) .. '</a>'
            table.insert(
                groups,
                result
            )
            if input and k:lower():match(input:lower()) then
                table.insert(
                    results,
                    result
                )
            end
        end
    end
    local output
    if #results > 0 then
        table.sort(results)
        output = '<b>Groups found matching:</b> ' .. mattata.escape_html(input) .. '\n' .. table.concat(
            results,
            '\n'
        )
    elseif #groups > 0 then
        table.sort(groups)
        output = '<b>Groups:</b>\n' .. table.concat(
            groups,
            '\n'
        )
    else
        output = configuration.errors.results
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

function administration.set_welcome_message(message, welcome_message)
    local hash = mattata.get_redis_hash(
        message,
        'welcome_message'
    )
    if hash then
        redis:hset(
            hash,
            'welcome_message',
            welcome_message
        )
        return 'Successfully set the new welcome message!'
    end
end

function administration.welcome(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'You must be an administrator in this chat to use this command.'
        )
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Use /setwelcome <message> to set a welcome message.'
        )
    end
    local validate = mattata.send_message(
        message.chat.id,
        input,
        'markdown'
    )
    if not validate then
        return mattata.send_reply(
            message,
            'There was an error formatting your message, please check your HTML syntax and try again.'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        validate.result.message_id,
        administration.set_welcome_message(message, input)
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
        message.chat.id,
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
        message.chat.id,
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
    redis:hset(
        hash,
        'rules',
        input
    )
    local success = mattata.send_message(
        message.chat.id,
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

function administration.rules(message)
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
        output = 'You need to speak to me in private chat before I can send you the rules! Just click [here](https://telegram.me/' .. configuration.info.username .. '), press the "START" button, and try again!'
    else
        output = 'I have sent you the rules via private chat!'
    end
    return mattata.send_reply(
        message,
        output,
        'markdown'
    )
end

function administration.custom(message)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    end
    if message.text:match('^%/custom new %#(%a+) (.-)$') then
        local trigger, value = message.text:match('^/custom new %#(%a+) (.-)$')
        trigger = '#' .. trigger
        redis:hset(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger),
            tostring(value)
        )
        return mattata.send_reply(
            message,
            'Success! That message will now be sent every time somebody uses ' .. trigger .. '!'
        )
    elseif message.text:match('^%/custom del %#(%a+)$') then
        local trigger = message.text:match('^%/custom del %#(%a+)$')
        local success = redis:hdel(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger)
        )
        if not success then
            return mattata.send_reply(
                message,
                'The trigger ' .. trigger .. ' does not exist!'
            )
        end
        return mattata.send_reply(
            message,
            'The trigger ' .. trigger .. ' has been deleted!'
        )
    elseif message.text == '/custom list' then
        local custom_commands = redis:hkeys('administration:' .. message.chat.id .. ':custom')
        if not next(custom_commands) then
            return mattata.send_reply(
                message,
                'You don\'t have any custom commands set!'
            )
        end
        local custom_commands_list = {}
        for k, v in ipairs(custom_commands) do
            table.insert(
                custom_commands_list,
                v
            )
        end
        return mattata.send_reply(
            message,
            'Custom commands for ' .. message.chat.title .. ':\n' .. table.concat(
                custom_commands_list,
                '\n'
            )
        )
    end
    return mattata.send_reply(
        message,
        'To create a new, custom command, use the following syntax:\n/custom new #trigger <value>. To list all current triggers, use /custom list. To delete a trigger, use /custom del #trigger.'
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
        message.chat.id,
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

function administration:on_message(message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        if message.text:match('^%/admins') or message.text:match('^%/staff') then
            return administration.admins(message)
        elseif message.text:match('^%/groups') then
            return administration.groups(message)
        elseif message.text:match('^%/link') then
            return administration.link(message)
        elseif message.text:match('^%/rules') then
            return administration.rules(message)
        elseif message.text:match('^%/ops') or message.text:match('^%/report') then
            return administration.report(message)
        elseif message.text:match('^%/chats') or message.text:match('^%/groups') then
            return administration.get_chats(message)
        end
        return -- Ignore all other requests from users who aren't administrators in the group.
    elseif message.text:match('^%/mod') or message.text:match('^%/promote') then
        return administration.mod(message)
    elseif message.text:match('^%/demod') or message.text:match('^%/demote') then
        return administration.demod(message)
    elseif message.text:match('^%/setwelcome') then
        return administration.welcome(message)
    elseif message.text:match('^%/blacklist') then
        return administration.blacklist(message)
    elseif message.text:match('^%/whitelist') then
        return administration.whitelist(message)
    elseif message.text:match('^%/kick') then
        return administration.kick(message)
    elseif message.text:match('^%/ban') then
        return administration.ban(message)
    elseif message.text:match('^%/unban') then
        return administration.unban(message, false)
    elseif message.text:match('^%/warn') then
        return administration.warn(message)
    elseif message.text:match('^%/setlink') then
        return administration.set_link(message)
    elseif message.text:match('^%/antispam') or message.text:match('^%/administration') then
        local keyboard = administration.get_initial_keyboard(message)
        return mattata.send_message(
            message.chat.id,
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
    elseif message.text:match('^%/admins') or message.text:match('^%/staff') then
        return administration.admins(message)
    elseif message.text:match('^%/groups') then
        return administration.groups(message)
    elseif message.text:match('^%/link') then
        return administration.link(message)
    elseif message.text:match('^%/custom') then
        return administration.custom(message)
    elseif message.text:match('^%/setrules') then
        return administration.set_rules(message)
    elseif message.text:match('^%/rules') then
        return administration.rules(message)
    elseif message.text:match('^%/pin') then
        return administration.pin(message)
    elseif message.text:match('^%/ops') or message.text:match('^%/report') then
        return administration.report(message)
    elseif message.text:match('^%/chats del .-$') or message.text:match('^%/groups del .-$') then
        return administration.del_chat(message)
    elseif message.text:match('^%/chats new .-$') or message.text:match('^%/groups new .-$') then
        return administration.new_chat(message)
    elseif message.text:match('^%/chats') or message.text:match('^%/groups') then
        return administration.get_chats(message)
    end
    return
end

return administration