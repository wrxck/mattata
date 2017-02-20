--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local administration = {}

local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function administration:init()
    administration.commands = mattata.commands(
        self.info.username
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
     :command('links')
     :command('link')
     :command('setlink')
     :command('custom')
     :command('rules')
     :command('setrules')
     :command('pin')
     :command('report')
     :command('ops')
     :command('user')
     :command('warns')
     :command('warnings')
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

function administration.get_initial_keyboard(chat_id)
    local current_status, new_status
    if redis:get(
        string.format(
            'administration:%s:enabled',
            chat_id
        )
    ) then
        current_status = 'Disable Administration'
        new_status = string.format(
            'administration:%s:disable',
            chat_id
        )
    else
        current_status = 'Enable Administration'
        new_status = string.format(
            'administration:%s:enable',
            chat_id
        )
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
                ['callback_data'] = string.format(
                    'administration:%s:antispam',
                    chat_id
                )
            }
        }
    )
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = '/warn Settings',
                ['callback_data'] = string.format(
                    'administration:%s:warning_settings',
                    chat_id
                )
            }
        }
    )
    local arabic_status = administration.get_hash_status(
        chat_id,
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
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_arabic_status
                )
            }
        }
    )
    local antibot_status = administration.get_hash_status(
        chat_id,
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
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_antibot_status
                )
            }
        }
    )
    local antilink_status = administration.get_hash_status(
        chat_id,
        'antilink'
    )
    local antilink_status_text = 'Enabled'
    local new_antilink_status = 'disable_antilink'
    if not antilink_status then
        antilink_status_text = 'Disabled'
        new_antilink_status = 'enable_antilink'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Anti-Link',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = antilink_status_text,
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_antilink_status
                )
            }
        }
    )
    local welcome_status = administration.get_hash_status(
        chat_id,
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
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_welcome_status
                )
            }
        }
    )
    local rules_on_join_status = administration.get_hash_status(
        chat_id,
        'rules_on_join'
    )
    local rules_on_join_status_text = 'Yes'
    local new_rules_on_join_status = 'disable_rules_on_join'
    if not rules_on_join_status then
        rules_on_join_status_text = 'No'
        new_rules_on_join_status = 'enable_rules_on_join'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Show rules on join?',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = rules_on_join_status_text,
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_rules_on_join_status
                )
            }
        }
    )
    local ban_kick_status = administration.get_hash_status(
        chat_id,
        'ban_kick'
    )
    local ban_kick_status_text = 'Ban'
    local new_ban_kick_status = 'disable_ban_kick'
    if not ban_kick_status then
        ban_kick_status_text = 'Kick'
        new_ban_kick_status = 'enable_ban_kick'
    end
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = 'Action on flood/max warnings',
                ['callback_data'] = 'administration:nil'
            },
            {
                ['text'] = ban_kick_status_text,
                ['callback_data'] = string.format(
                    'administration:%s:%s',
                    chat_id,
                    new_ban_kick_status
                )
            }
        }
    )
    return keyboard
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

function administration.get_warning_settings(chat_id)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current = redis:get(
        string.format(
            'administration:%s:max_warnings',
            chat_id
        )
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

function administration.check_links(message, process_type)
    local links = {}
    if message.entities then
        for i = 1, #message.entities do
            if message.entities[i].type == 'text_link' then
                message.text = message.text .. ' ' .. message.entities[i].url
            end
        end
    end
    for n in message.text:lower():gmatch('%@[%w%_]+') do
        table.insert(
            links,
            n:match('^%@([%w%_]+)$')
        )
    end
    for n in message.text:lower():gmatch('t%.me%/joinchat/[%w%_]+') do
        table.insert(
            links,
            n:match('%/(joinchat%/[%w%_]+)$')
        )
    end
    for n in message.text:lower():gmatch('t%.me%/[%w%_]+') do
        if not n:match('%/joinchat$') then
            table.insert(
                links,
                n:match('%/([%w%_]+)$')
            )
        end
    end
    for n in message.text:lower():gmatch('telegram%.me%/joinchat/[%w%_]+') do
        table.insert(
            links,
            n:match('%/(joinchat%/[%w%_]+)$')
        )
    end
    for n in message.text:lower():gmatch('telegram%.me%/[%w%_]+') do
        if not n:match('%/joinchat$') then
            table.insert(
                links,
                n:match('%/([%w%_]+)$')
            )
        end
    end
    for n in message.text:lower():gmatch('telegram%.dog%/joinchat/[%w%_]+') do
        table.insert(
            links,
            n:match('%/(joinchat%/[%w%_]+)$')
        )
    end
    for n in message.text:lower():gmatch('telegram%.dog%/[%w%_]+') do
        if not n:match('%/joinchat$') then
            table.insert(
                links,
                n:match('%/([%w%_]+)$')
            )
        end
    end
    if process_type == 'whitelist' then
        local count = 0
        for k, v in pairs(links) do
            if not redis:get(
                string.format(
                    'whitelisted_links:%s:%s',
                    message.chat.id,
                    v
                )
            ) then
                redis:set(
                    string.format(
                        'whitelisted_links:%s:%s',
                        message.chat.id,
                        v
                    ),
                    true
                )
                count = count + 1
            end
        end
        return count .. ' links have been whitelisted in this chat!'
    elseif process_type == 'check' then
        for k, v in pairs(links) do
            if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. v) then
                if not v:match('^joinchat%/') then
                    local resolved = mattata.get_chat('@' .. v)
                    if resolved then
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

function administration.is_user_spamming(message) -- Checks if a user is spamming and return two boolean values
    local messages = redis:get('administration:text:' .. message.chat.id .. ':' .. message.from.id)
    local forwarded = redis:get('administration:forwarded:' .. message.chat.id .. ':' .. message.from.id)
    local stickers = redis:get('administration:stickers:' .. message.chat.id .. ':' .. message.from.id)
    if redis:get('administration:' .. message.chat.id .. ':antilink') and administration.check_links(
        message,
        'check'
    ) then
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

function administration.blacklist(message, bot_info)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            [[Please reply-to the user you'd like to blacklist, or specify them by username/ID.]]
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                [[I can't blacklist that user, they're an administrator in this chat.]]
            )
        elseif message.reply_to_message.from.id == username then
            return
        end
        redis:set(
            'group_blacklist:' .. message.chat.id .. ':' .. message.reply_to_message.from.id,
            true
        )
        local output = string.format(
            '%s [%s] has blacklisted %s [%s] from using @%s in %s [%s].',
            message.from.first_name,
            message.from.id,
            message.reply_to_message.from.first_name,
            message.reply_to_message.from.id,
            bot_info.username:lower(),
            message.chat.title,
            message.chat.id
        )
        if input then
            output = string.format(
                '%s\nReason: %s',
                output,
                input
            )
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_user(input)
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
        elseif resolved.result.id == bot_info.id then
            return
        end
        redis:set(
            'group_blacklist:' .. message.chat.id .. ':' .. resolved.result.id,
            true
        )
        local output = string.format(
            '%s [%s] has blacklisted %s [%s] from using @%s in %s [%s].',
            message.from.first_name,
            message.from.id,
            resolved.result.first_name,
            resolved.result.id,
            bot_info.username:lower(),
            message.chat.title,
            message.chat.id
        )
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

function administration.whitelist(message, bot_info)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            [[Please reply-to the user you'd like to whitelist, or specify them by username/ID.]]
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(
            message.chat.id,
            message.reply_to_message.from.id
        ) then
            return mattata.send_reply(
                message,
                [[I can't whitelist that user, they're an administrator in this chat.]]
            )
        elseif message.reply_to_message.from.id == bot_info.id then
            return
        end
        redis:del('group_blacklist:' .. message.chat.id .. ':' .. message.reply_to_message.from.id)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] to use @' .. bot_info.username:lower() .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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
            message,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_user(input)
        if not resolved then
            return mattata.send_reply(
                message,
                string.format(
                    [[I couldn't get information about %s, please ensure it's a valid username/ID and try again.]],
                    input
                )
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                string.format(
                    [[That's a %s, not a user!]],
                    resolved.result.type
                )
            )
        end
        if mattata.is_group_admin(
            message.chat.id,
            resolved.result.id
        ) then
            return mattata.send_reply(
                message,
                [[I can't whitelist that user, they're an administrator in this chat.]]
            )
        elseif resolved.result.id == bot_info.id then
            return
        end
        redis:del('group_blacklist:' .. message.chat.id .. ':' .. resolved.result.id)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] to use @' .. bot_info.username:lower() .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message,
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
    local input = mattata.input(message.text)
    local output = false
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
                if output == false then
                    output = {}
                end
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
    if output == false then
        local output = 'No groups were found. If you\'d like your group to appear here, contact @wrxck.'
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

function administration.do_action(message, action)
    action = action:lower() or false
    if action ~= 'kick' and action ~= 'ban' and action ~= 'unban' then
        return
    end
    local input, reason = message.reply_to_message and message.reply_to_message.from.id or mattata.input(message.text), false
    if not input then
        return mattata.send_reply(
            message,
            string.format(
                'Please specify the user you\'d like me to %s.',
                action
            )
        )
    end
    input = tostring(input)
    if input:match('^.- .-$') then
        input, reason = input:match('^(.-) (.-)$')
    end
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator of this chat to use this command.'
        )
    elseif not input then
        return mattata.send_reply(
            message,
            string.format(
                'Please reply-to the user you\'d like to %s, or specify them by username/ID.',
                action
            )
        )
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local user = mattata.get_user(input)
    if not user then
        return mattata.send_reply(
            message,
            'I don\'t recognise that user! To teach me who they are, ask them to send me a message, or you can forward a message from them to me.'
        )
    end
    if user.result.id == mattata.get_me().result.id or not mattata.get_chat_member(
        message.chat.id,
        user.result.id
    ) then
        return
    elseif mattata.is_group_admin(
        message.chat.id,
        user.result.id
    ) then
        return mattata.send_reply(
            message,
            string.format(
                'I can\'t %s %s%s because they have administrator privileges in this chat.',
                action,
                user.result.username and '@' or '',
                user.result.username or user.result.first_name
            )
        )
    end
    local success
    if action == 'kick' then
        success = mattata.kick_chat_member(
            message.chat.id,
            user.result.id
        )
    elseif action == 'ban' then
        success = mattata.ban_chat_member(
            message.chat.id,
            user.result.id
        )
    else
        success = mattata.unban_chat_member(
            message.chat.id,
            user.result.id
        )
    end
    if not success then
        return mattata.send_reply(
            message,
            string.format(
                'I couldn\'t %s %s because I don\'t have administrator privileges in this chat!',
                action,
                user.result.first_name
            )
        )
    end
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
        mattata.send_message(
            configuration.log_channel,
            string.format(
                '<pre>%s [%s] has %s %s [%s] from %s [%s]%s</pre>',
                mattata.escape_html(message.from.first_name),
                message.from.id,
                action:match('ban$') and action .. 'ned' or action .. 'ed',
                mattata.escape_html(user.result.first_name),
                user.result.id,
                mattata.escape_html(message.chat.title),
                message.chat.id,
                reason and (' for ' .. reason .. '.') or '.'
            ),
            'html'
        )
    end
    redis:hincrby(
        string.format(
            'user:%s:%s_count',
            user.result.id,
            action
        ),
        message.chat.id,
        1
    )
    return mattata.send_message(
        message,
        string.format(
            '%s has %s %s%s%s',
            message.from.first_name,
            action:match('ban$') and action .. 'ned' or action .. 'ed',
            user.result.username and '@' or '',
            user.result.username or user.result.first_name,
            reason and ' for ' .. reason .. '.' or '.'
        )
    )
end

function administration.tempban(message)
    local input = mattata.input(message.text)
    if (
        not input and not message.reply_to_message
    ) or (
        input and not message.reply_to_message and not input:match('^%@%a+ %d*')
    ) or (
        input and message.reply_to_message and not input:match('^%d*')
    ) then
        return mattata.send_reply(
            message,
            'Please specify the user you\'d like to temp-ban, and how long you\'d like to temp-ban them for. This must be sent in the format /tempban [user] <hours> [reason]. If a user isn\'t specified then you must use this command in reply to the user you\'d like to temp-ban.'
        )
    end
    local user = input:match('^(%@%a+) %d*') or message.reply_to_message.from.id
    if tonumber(user) == nil then
        user = mattata.get_user(user)
        if not user then
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
    ) then
        return mattata.send_reply(
            message,
            'I can\'t temp-ban that user because they\'re a staff member of this chat!'
        )
    elseif not mattata.get_chat_member(
        message.chat.id,
        user
    ) then
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
    ) then
        return mattata.send_reply(
            message,
            'That user is already temp-banned!'
        )
    end
    local user_info = mattata.get_chat_member(
        message.chat.id,
        user
    )
    local reason = input:match('%d* (.-)$') or false
    local hours = input:match('^%@%a+ (%d*)$') or input:match('^%@%a+ (%d*) .-$') or input:match('^(%d*)$') or input:match('^(%d*) .-$')
    if tonumber(hours) == nil or tonumber(hours) < 1 or tonumber(hours) > 168 then
        return mattata.send_reply(
            message,
            'The minimum time you can temp-ban a user for is 1 hour. The maximum time you can temp-ban a user for is 168 hours (1 week).'
        )
    end
    local success = mattata.ban_chat_member(
        message.chat.id,
        user
    )
    if not success then
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
    if tonumber(hours) > 1 then
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
    if reason ~= false then
        output = output .. '\nReason: ' .. reason
    end
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
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
        local success = mattata.ban_chat_member(
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
            message,
            text
        )
    end
    local difference = maximum - amount
    text = '*%s* has been warned `[`%d/%d`]`'
    if message.text ~= '/warn' then
        text = text .. '\n*Reason:* ' .. mattata.escape_markdown(
            message.text:lower():gsub('^/warn ', '')
        )
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
                            message.reply_to_message.from.id
                        )
                    },
                    {
                        ['text'] = 'Remove 1 Warning',
                        ['callback_data'] = string.format(
                            'administration:warn:remove:%s:%s',
                            message.chat.id,
                            message.reply_to_message.from.id
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

function administration.get_user(message)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            [[You must use this command in reply-to a message from the user you'd like to view information about.]]
        )
    end
    local ban_count = redis:hget(
        string.format(
            'user:%s:ban_count',
            message.reply_to_message.from.id
        ),
        message.chat.id
    )
    if not ban_count then
        ban_count = 0
    end
    ban_count = ban_count .. ' time'
    if ban_count ~= '1 time' then
        ban_count = ban_count .. 's'
    else
        ban_count = 'once'
    end
    if ban_count == '2 times' then
        ban_count = 'twice'
    end
    local kick_count = redis:hget(
        string.format(
            'user:%s:kick_count',
            message.reply_to_message.from.id
        ),
        message.chat.id
    )
    if not kick_count then
        kick_count = 0
    end
    kick_count = kick_count .. ' time'
    if kick_count ~= '1 time' then
        kick_count = kick_count .. 's'
    else
        kick_count = 'once'
    end
    if kick_count == '2 times' then
        kick_count = 'twice'
    end
    local warning_count = redis:hget(
        string.format(
            'chat:%s:warnings',
            message.chat.id
        ),
        message.reply_to_message.from.id
    )
    if not warning_count then
        warning_count = 0
    end
    local output = string.format(
        '%s [%s]\n\nBanned %s\nKicked %s\n%s/3 warnings',
        message.reply_to_message.from.first_name,
        message.reply_to_message.from.id,
        ban_count,
        kick_count,
        warning_count
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
                            message.reply_to_message.from.id
                        )
                    },
                    {
                        ['text'] = 'Remove 1 Warning',
                        ['callback_data'] = string.format(
                            'administration:warn:remove:%s:%s',
                            message.chat.id,
                            message.reply_to_message.from.id
                        )
                    }
                }
            }
        }
    )
    if tonumber(warning_count) < 1 then
        keyboard = nil
    end
    return mattata.send_message(
        message,
        output,
        nil,
        true,
        false,
        nil,
        keyboard
    )
end

function administration:on_callback_query(callback_query, message, configuration)
    if callback_query.data == 'nil' then
        return mattata.answer_callback_query(callback_query.id)
    elseif not callback_query.data:match('^warn%:') and not mattata.is_group_admin(
        callback_query.data:match('^(%-%d+)'),
        callback_query.from.id
    ) then
        return mattata.answer_callback_query(
            callback_query.id,
            'You\'re not an administrator in that chat!'
        )
    elseif callback_query.data:match('^warn%:%a+%:%-%d+%:%d+$') then
        if not mattata.is_group_admin(
            callback_query.data:match('^warn%:%a+%:(%-%d+)%:%d+$'),
            callback_query.from.id
        ) then
            return mattata.answer_callback_query(
                callback_query.id,
                'You need to be an administrator in order to use this!'
            )
        end
    end
    local keyboard
    if callback_query.data:match('^%-%d+:antispam$') then
        local chat_id = callback_query.data:match('^(%-%d+):antispam$')
        keyboard = administration.get_antispam_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:limit%:.-%:.-$') then
        local chat_id, spam_type, limit = callback_query.data:match('^(%-%d+)%:limit%:(.-)%:(.-)$')
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
    elseif callback_query.data:match('^%-%d+:warning%_settings$') then
        local chat_id = callback_query.data:match('^(%-%d+):warning%_settings$')
        keyboard = administration.get_warning_settings(chat_id)
    elseif callback_query.data:match('^%-%d+%:max%_warnings%:.-$') then
        local chat_id, max_warnings = callback_query.data:match('^(%-%d+)%:max%_warnings%:(.-)$')
        if tonumber(max_warnings) > 10 then
            return mattata.answer_callback_query(
                callback_query.id,
                'The maximum number of warnings is 10.'
            )
        elseif tonumber(max_warnings) < 2 then
            return mattata.answer_callback_query(
                callback_query.id,
                'The minimum number of warnings is 2.'
            )
        elseif tonumber(max_warnings) == nil then
            return
        end
        redis:set(
            string.format(
                'administration:%s:max_warnings',
                chat_id
            ),
            tonumber(max_warnings)
        )
        keyboard = administration.get_warning_settings(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable$')
        redis:set(
            string.format(
                'administration:%s:enabled',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable$')
        redis:del('administration:' .. chat_id .. ':enabled')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_rtl$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_rtl$')
        redis:set(
            string.format(
                'administration:%s:rtl',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_rtl$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_rtl$')
        redis:del('administration:' .. chat_id .. ':rtl')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_rules%_on%_join$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_rules%_on%_join$')
        redis:set(
            string.format(
                'administration:%s:rules_on_join',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_rules%_on%_join$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_rules%_on%_join$')
        redis:del('administration:' .. chat_id .. ':rules_on_join')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable_ban_kick$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable_ban_kick$')
        redis:set(
            string.format(
                'administration:%s:ban_kick',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable_ban_kick$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable_ban_kick$')
        redis:del('administration:' .. chat_id .. ':ban_kick')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_antibot$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_antibot$')
        redis:set(
            string.format(
                'administration:%s:antibot',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_antibot$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_antibot$')
        redis:del('administration:' .. chat_id .. ':antibot')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_antilink$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_antilink$')
        redis:set(
            string.format(
                'administration:%s:antilink',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_antilink$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_antilink$')
        redis:del('administration:' .. chat_id .. ':antilink')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_welcome$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_welcome$')
        redis:set(
            string.format(
                'administration:%s:welcome',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_welcome$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_welcome$')
        redis:del('administration:' .. chat_id .. ':welcome')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:enable%_admins%_only$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:enable%_admins%_only$')
        redis:set(
            string.format(
                'administration:%s:admins_only',
                chat_id
            ),
            true
        )
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:disable%_admins%_only$') then
        local chat_id = callback_query.data:match('^(%-%d+)%:disable%_admins%_only$')
        redis:del('administration:' .. chat_id .. ':admins_only')
        keyboard = administration.get_initial_keyboard(chat_id)
    elseif callback_query.data:match('^%-%d+%:ahelp$') then
        keyboard = administration.get_help_keyboard(callback_query.data:match('^(%-%d+)%:ahelp$'))
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration.get_help_text('back'),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^%-%d+%:ahelp%:.-$') then
        return administration.on_help_callback_query(
            callback_query,
            callback_query.data:match('^%-%d+%:ahelp%:.-$')
        )
    elseif callback_query.data:match('^%-%d+%:back$') then
        keyboard = administration.get_initial_keyboard(callback_query.data:match('^(%-%d+)%:back$'))
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^warn%:reset%:%-%d+%:%d+$') then
        redis:hdel(
            string.format(
                'chat:%s:warnings',
                callback_query.data:match('^warn%:reset%:(%-%d+)%:%d+$')
            ),
            callback_query.data:match('^warn%:reset%:%-%d+%:(%d+)$')
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Warnings reset by ' .. callback_query.from.first_name
        )
    elseif callback_query.data:match('^warn%:remove%:%-%d+%:%d+$') then
        local chat_id = callback_query.data:match('^warn%:remove%:(%-%d+)%:%d+$')
        local user_id = callback_query.data:match('^warn%:remove%:%-%d+%:(%d+)$')
        local amount = redis:hincrby(
            string.format(
                'chat:%s:warnings',
                chat_id
            ),
            user_id,
            -1
        )
        local text, maximum, difference
        if tonumber(amount) < 0 then
            text = 'The number of warnings received by this user is already zero!'
            redis:hincrby(
                string.format(
                    'chat:%s:warnings',
                    chat_id
                ),
                user_id,
                1
            )
        else
            maximum = 3
            difference = tonumber(maximum) - tonumber(amount)
            text = string.format(
                'Warning removed by %s! [%d/%d]',
                callback_query.from.first_name,
                tonumber(amount),
                tonumber(maximum)
            )
        end
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            text
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
    if not success and redis:get(
        string.format(
            'administration:%s:pin',
            message.chat.id
        )
    )then
        mattata.send_reply(
            message,
            [[There was an error whilst updating your pin. Either the text you entered contained invalid Markdown syntax, or the pin has been deleted. I'm now going to try and send you a new pin, which you'll be able to find below - if you need to modify it then, after ensuring the message still exists, use /pin <text>.]]
        )
    elseif not success then
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
    if redis:get(
        string.format(
            'administration:%s:ban_not_kick',
            message.chat.id
        )
    ) then
        success = mattata.kick_chat_member(
            message.chat.id,
            message.from.id
        )
        executed_action = 'kicked'
    else
        success = mattata.ban_chat_member(
            message.chat.id,
            message.from.id
        )
        executed_action = 'banned'
    end
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
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
    end
    return welcome_message
end

function administration:on_new_chat_member(message)
    if message.new_chat_member.id == self.info.id then
        return mattata.send_message(
            message,
            string.format(
                'Thanks for adding me to %s, %s! I can be used the way I am, but if you want to enable my administration functionality, use /administration. To disable my AI functionality, use /plugins.',
                message.chat.title,
                message.from.first_name
            )
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and redis:get('administration:' .. message.chat.id .. ':antibot') and message.new_chat_member.username and message.new_chat_member.username:lower():match('bot$') and message.new_chat_member.id ~= message.from.id then
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.new_chat_member.id
        )
        if success then
            if configuration.log_admin_actions and configuration.log_channel ~= '' then
                mattata.send_message(
                    configuration.log_channel,
                    string.format(
                        '<pre>%s has kicked %s [%s] from %s [%s] because anti-bot is enabled.</pre>',
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
    elseif not redis:get(
        string.format(
            'administration:%s:welcome',
            message.chat.id
        )
    ) then
        return
    end
    local welcome_message = administration.get_welcome_message(message)
    if not welcome_message then
        local join_messages = configuration.join_messages
        local name = message.new_chat_member.first_name:gsub('%%', '%%%%')
        local output = join_messages[math.random(#join_messages)]:gsub('NAME', name)
        if redis:get(
            string.format(
                'administration:%s:rules_on_join',
                message.chat.id
            )
        ) then
            return mattata.send_message(
                message,
                output,
                'markdown',
                true,
                false,
                nil,
                json.encode(
                    {
                        ['inline_keyboard'] = {
                            {
                                {
                                    ['text'] = utf8.char(128218) .. ' Group Rules',
                                    ['url'] = string.format(
                                        'https://telegram.me/%s?start=%s:rules',
                                        self.info.username:lower(),
                                        message.chat.id
                                    )
                                }
                            }
                        }
                    }
                )
            )
        else
            return mattata.send_message(
                message,
                output,
                'markdown',
                true
            )
        end
    else
        local name = message.new_chat_member.first_name
        if message.new_chat_member.last_name then
            name = name .. ' ' .. message.new_chat_member.last_name
        end
        name = name:gsub('%%', '%%%%')
        name = mattata.escape_markdown(name)
        local title = message.chat.title:gsub('%%', '%%%%')
        title = mattata.escape_markdown(title)
        welcome_message = welcome_message:gsub('%$user%_id', message.new_chat_member.id):gsub('%$chat%_id', message.chat.id):gsub('%$name', name):gsub('%$title', title)
        return mattata.send_message(
            message,
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
                                    self.info.username:lower(),
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

function administration.report(message, bot_id)
    if not message.reply_to_message then
        return
    elseif message.reply_to_message.from.id == message.from.id then
        return
    end
    local admin_list = {}
    local admins = mattata.get_chat_administrators(message.chat.id)
    local notified = 0
    for n in pairs(admins.result) do
        if admins.result[n].user.id ~= bot_id then
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
        message,
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
        'This user is now a moderator in this chat. They have access to administrative commands such as /ban, /kick and /unban. To demote them, just reply to one of their messages with /demod.'
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
        'This user is no longer a moderator in this chat. They no longer have access to administrative commands such as /ban, /kick and /unban. To promote them again, just reply to one of their messages with /mod.'
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
        message,
        input,
        'markdown'
    )
    if not validate then
        return mattata.send_reply(
            message,
            'There was an error formatting your message, please check your Markdown syntax and try again.'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        validate.result.message_id,
        administration.set_welcome_message(
            message,
            input
        )
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
        if message.text:match('^[%/%!%$%^%?%&%%]admins') or message.text:match('^[%/%!%$%^%?%&%%]staff') then
            return administration.admins(message)
        elseif message.text:match('^[%/%!%$%^%?%&%%]link') then
            return administration.link(message)
        elseif message.text:match('^[%/%!%$%^%?%&%%]rules') then
            return administration.rules(
                message,
                self.info.username:lower()
            )
        elseif message.text:match('^[%/%!%$%^%?%&%%]ops') or message.text:match('^[%/%!%$%^%?%&%%]report') then
            return administration.report(
                message,
                self.info.id
            )
        elseif message.text:match('^[%/%!%$%^%?%&%%]chats') or message.text:match('^[%/%!%$%^%?%&%%]groups') then
            return administration.get_chats(message)
           elseif message.text:match('^[%/%!%$%^%?%&%%]user') or message.text:match('^[%/%!%$%^%?%&%%]warns') or message.text:match('^[%/%!%$%^%?%&%%]warnings') then
            return administration.get_user(message)
        end
        return -- Ignore all other requests from users who aren't administrators in the group.
    elseif message.text:match('^[%/%!%$%^%?%&%%]mod') or message.text:match('^[%/%!%$%^%?%&%%]promote') then
        return administration.mod(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]demod') or message.text:match('^[%/%!%$%^%?%&%%]demote') then
        return administration.demod(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]setwelcome') then
        return administration.welcome(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]blacklist') then
        return administration.blacklist(
            message,
            self.info
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]whitelist') then
        return administration.whitelist(
            message,
            self.info
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]kick') then
        return administration.do_action(
            message,
            'kick'
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]ban') then
        return administration.do_action(
            message,
            'ban'
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]unban') then
        return administration.do_action(
            message,
            'unban'
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]user') or message.text:match('^[%/%!%$%^%?%&%%]warns') or message.text:match('^[%/%!%$%^%?%&%%]warnings') then
        return administration.get_user(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]warn') then
        return administration.warn(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]setlink') then
        return administration.set_link(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]antispam') or message.text:match('^[%/%!%$%^%?%&%%]administration') then
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
    elseif message.text:match('^[%/%!%$]admins') or message.text:match('^[%/%!%$%^%?%&%%]staff') then
        return administration.admins(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]links') then
        return administration.whitelist_links(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]link') then
        return administration.link(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]custom') then
        return administration.custom(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]setrules') then
        return administration.set_rules(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]rules') then
        return administration.rules(
            message,
            self.info.username:lower()
        )
    elseif message.text:match('^[%/%!%$%^%?%&%%]pin') then
        return administration.pin(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]ops') or message.text:match('^[%/%!%$%^%?%&%%]report') then
        return administration.report(
            message,
            self.info.id
        )
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[%/%!%$%^%?%&%%]chats del .-$') or message.text:match('^[%/%!%$%^%?%&%%]groups del .-$') then
        return administration.del_chat(message)
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^[%/%!%$%^%?%&%%]chats new .-$') or message.text:match('^[%/%!%$%^%?%&%%]groups new .-$') then
        return administration.new_chat(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]chats') or message.text:match('^[%/%!%$%^%?%&%%]groups') then
        return administration.get_chats(message)
    elseif message.text:match('^[%/%!%$%^%?%&%%]tempban') then
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
            local chat_id, user_id = v:match('^(%-%d+)%:(%d+)$')
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