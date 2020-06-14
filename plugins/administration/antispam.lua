--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local antispam = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function antispam:init(configuration)
    antispam.commands = mattata.commands(self.info.username):command('antispam').table
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
        'contact',
        'dice',
        'poll'
    }
    antispam.default_values = {
        ['text'] = configuration.administration.default.antispam.text,
        ['forwarded'] = configuration.administration.default.antispam.forwarded,
        ['sticker'] = configuration.administration.default.antispam.sticker,
        ['photo'] = configuration.administration.default.antispam.photo,
        ['video'] = configuration.administration.default.antispam.video,
        ['location'] = configuration.administration.default.antispam.location,
        ['voice'] = configuration.administration.default.antispam.voice,
        ['game'] = configuration.administration.default.antispam.game,
        ['venue'] = configuration.administration.default.antispam.venue,
        ['video note'] = configuration.administration.default.antispam.video_note,
        ['invoice'] = configuration.administration.default.antispam.invoice,
        ['contact'] = configuration.administration.default.antispam.contact,
        ['dice'] = configuration.administration.default.antispam.dice,
        ['poll'] = configuration.administration.default.antispam.poll
    }
end

function antispam.on_member_join(_, message)
    for _, user in pairs(message.new_chat_members) do
        redis:set('join_time:' .. user.id .. ':' .. message.chat.id, os.time())
    end
end

function antispam:on_new_message(message, configuration, language)
    if message.from.id == 777000 then
        return false
    end
    -- Thanks to GingerPlusPlus for the idea
    if message.chat.type ~= 'private' and mattata.get_setting(message.chat.id, 'remove pasted code') then
        if message.entities then
            for _, entity in pairs(message.entities) do
                if (entity.type == 'pre' or entity.type == 'code') and entity.length > configuration.administration.global_antispam.max_code_length and not mattata.is_group_admin(message.chat.id, message.from.id) then
                    local success = mattata.delete_message(message.chat.id, message.message_id)
                    if success then
                        local name = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
                        local output = string.format(language['antispam']['11'], name, configuration.administration.global_antispam.max_code_length, self.info.username:lower())
                        return mattata.send_message(message.chat.id, output, 'html', true)
                    end
                    return false
                end
            end
        end
    end
    if message.chat.type == 'supergroup' and mattata.get_setting(message.chat.id, 'antilink') and message.is_invite_link then
        if not mattata.is_group_admin(message.chat.id, message.from.id) and not mattata.is_global_admin(message.from.id) and message.is_invite_link then
            local action = mattata.get_setting(message.chat.id, 'ban not kick') and mattata.ban_chat_member or mattata.kick_chat_member
            local punishment = mattata.get_setting(message.chat.id, 'ban not kick') and 'banned' or 'kicked'
            local success = action(message.chat.id, message.from.id)
            local output
            if success then
                local banned_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
                if mattata.get_setting(message.chat.id, 'log administrative actions') then
                    local log_chat = mattata.get_log_chat(message.chat.id)
                    local admin_username = mattata.get_formatted_user(self.info.id, self.info.first_name, 'html')
                    output = string.format(language['antispam']['12'], admin_username, self.info.id, punishment, banned_username, message.from.id, mattata.escape_html(message.chat.title), message.chat.id, tostring(message.chat.id):gsub('^%-100', ''), message.from.id)
                    mattata.send_message(log_chat, output, 'html')
                else
                    output = string.format(language['antispam']['13'], punishment:gsub('^%l', string.upper), banned_username)
                    mattata.send_message(message.chat.id, output, 'html')
                end
                mattata.delete_message(message.chat.id, message.message_id)
                return
            end
        else
            local whitelisted = true
            local links = mattata.check_links(message, true, true)
            if links and #links > 0 then
                for _, link in pairs(links) do
                    if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. link) and not mattata.table_contains(configuration.administration.allowed_links, link:lower()) then
                        whitelisted = false
                        break
                    end
                end
            end
            if not whitelisted and not message.text:match('^[!/#]whitelistlink') and not message.text:match('^[!/#]wl') then
                return mattata.send_reply(message, language['antispam']['14'])
            end
        end
    end
    local messages = redis:get('messages:' .. message.from.id .. ':' .. message.chat.id) or 0
    local join_time = redis:get('join_time:' .. message.from.id .. ':' .. message.chat.id)
    if message.chat.type == 'supergroup' and not mattata.is_group_admin(message.chat.id, message.from.id) and messages <= 3 and join_time and mattata.get_setting(message.chat.id, 'kick urls on join') and message.entities then
        for _, entity in pairs(message.entities) do
            if entity.type == 'url' then
                redis:del('messages:' .. message.from.id .. ':' .. message.chat.id)
                local log_actions = mattata.get_setting(message.chat.id, 'log administrative actions')
                local log_chat = mattata.get_log_chat(message.chat.id)
                local kicked_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
                local output = string.format(language['antispam']['16'], kicked_username, message.from.id, mattata.escape_html(message.chat.title), message.chat.id, tostring(message.chat.id):gsub('^%-100', ''), message.from.id)
                for _, entities in pairs(message.entities) do
                    if entities.type == 'url' then
                        mattata.delete_message(message.chat.id, message.message_id)
                        if log_actions then
                            mattata.send_message(log_chat, output, 'html')
                        end
                        return mattata.kick_chat_member(message.chat.id, message.from.id)
                    end
                end
            end
        end
    end
    if message.chat.type == 'supergroup' and (message.entities or message.photo or message.document) and mattata.get_setting(message.chat.id, 'kick media on join') and messages <= 2 and not mattata.is_group_admin(message.chat.id, message.from.id) and join_time then
        redis:del('messages:' .. message.from.id .. ':' .. message.chat.id)
        local log_actions = mattata.get_setting(message.chat.id, 'log administrative actions')
        local log_chat = mattata.get_log_chat(message.chat.id)
        local kicked_username = mattata.get_formatted_user(message.from.id, message.from.first_name, 'html')
        local output = string.format(language['antispam']['15'], kicked_username, message.from.id, mattata.escape_html(message.chat.title), message.chat.id, tostring(message.chat.id):gsub('^%-100', ''), message.from.id)
        if message.photo or message.document then
            mattata.delete_message(message.chat.id, message.message_id)
            if log_actions then
                mattata.send_message(log_chat, output, 'html')
            end
            return mattata.kick_chat_member(message.chat.id, message.from.id)
        end
    end
end

function antispam.get_keyboard(chat_id, language)
    local status = redis:hget('chat:' .. chat_id .. ':settings', 'antispam') and true or false
    local caption = status and language['antispam']['1'] or language['antispam']['2']
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = caption,
        ['callback_data'] = 'antispam:' .. chat_id .. ':' .. caption:lower()
    }})
    if status then
        for _, media in pairs(antispam.media_types) do
            local current = mattata.get_value(chat_id, media .. ' limit') or antispam.default_values[media]
            if not mattata.get_setting(chat_id, 'allow ' .. media) then
                table.insert(keyboard.inline_keyboard, {{
                    ['text'] = media:gsub('^%l', string.upper),
                    ['callback_data'] = 'antispam:nil'
                }, {
                    ['text'] = '-',
                    ['callback_data'] = 'antispam:' .. chat_id .. ':limit:' .. media .. ':' .. tonumber(current) - 1
                }, {
                    ['text'] = tostring(current),
                    ['callback_data'] = 'antispam:nil'
                }, {
                    ['text'] = '+',
                    ['callback_data'] = 'antispam:' .. chat_id .. ':limit:' .. media .. ':' .. tonumber(current) + 1
                }, {
                    ['text'] = language['antispam']['3'],
                    ['callback_data'] = 'antispam:' .. chat_id .. ':toggle:' .. media
                }})
            else
                table.insert(keyboard.inline_keyboard, {{
                    ['text'] = media:gsub('^%l', string.upper),
                    ['callback_data'] = 'antispam:nil'
                }, {
                    ['text'] = string.format(language['antispam']['4'], media),
                    ['callback_data'] = 'antispam:' .. chat_id .. ':toggle:' .. media
                }})
            end
        end
    end
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = mattata.symbols.back .. ' ' .. language['antispam']['5'],
        ['callback_data'] = 'administration:' .. chat_id .. ':page:1'
    }})
    return keyboard
end

function antispam.is_user_spamming(message)
    if message.media_type == '' or mattata.get_setting(message.chat.id, 'allow ' .. message.media_type) then
        return false
    end
    local limit = mattata.get_value(message.chat.id, message.media_type .. ' limit') or antispam.default_values[message.media_type]
    local current = redis:get('antispam:' .. message.media_type .. ':' .. message.chat.id .. ':' .. message.from.id) or 1
    redis:setex('antispam:' .. message.media_type .. ':' .. message.chat.id .. ':' .. message.from.id, 5, tonumber(current) + 1)
    if tonumber(current) == tonumber(limit) then
        return true, message.media_type
    elseif message.media_type == 'rtl' and mattata.get_setting(message.chat.id, 'antirtl') then
        return true, 'rtl'
    end
    return false
end

function antispam:process_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        return false, 'The chat is not a supergroup!'
    elseif mattata.is_group_admin(message.chat.id, message.from.id) then
        return false, 'That user is an administrator in this chat!'
    elseif mattata.is_global_admin(message.from.id) then
        return false, 'That user is a global admin!'
    elseif not mattata.get_setting(message.chat.id, 'use administration') then
        return false, 'The administration plugin is switched off in this chat!'
    elseif not mattata.get_setting(message.chat.id, 'antispam') then
        return false, 'The antispam plugin is switched off in this chat!'
    end
    local is_spamming, media_type = antispam.is_user_spamming(message)
    if not is_spamming then
        return false, 'This user is not spamming!'
    end
    local action = mattata.get_setting(message.chat.id, 'ban not kick') and mattata.ban_chat_member or mattata.kick_chat_member
    local success, error_message = action(message.chat.id, message.from.id)
    if not success then
        return false, error_message
    elseif mattata.get_setting(message.chat.id, 'log administrative actions') then
        mattata.send_message(
            mattata.get_log_chat(message.chat.id),
            string.format(
                '<pre>' .. language['antispam']['6'] .. '</pre>',
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
            language['antispam']['7'],
            message.from.username and '@' .. message.from.username or message.from.first_name,
            media_type
        )
    )
end

function antispam.on_callback_query(_, callback_query, message, _, language)
    local chat_id = (message and message.chat and message.chat.type == 'supergroup') and message.chat.id or callback_query.data:match('^(%-%d+):?')
    if not chat_id then
        mattata.answer_callback_query(callback_query.id, language['errors']['generic'])
        return false, 'No chat ID was found!'
    elseif not mattata.is_group_admin(chat_id, callback_query.from.id) then
        mattata.answer_callback_query(callback_query.id, language['errors']['admin'])
        return false, 'That user is not an admin/mod in this chat!'
    end
    if callback_query.data:match('^%-%d+:limit:.-:.-$') then
        local spam_type, limit = callback_query.data:match('^%-%d+:limit:(.-):(.-)$')
        if tonumber(limit) > 100 then
            local output = language['antispam']['8']
            mattata.answer_callback_query(callback_query.id, output)
            return false, output
        elseif tonumber(limit) < 1 then
            local output = language['antispam']['9']
            mattata.answer_callback_query(callback_query.id, output)
            return false, output
        elseif tonumber(limit) == nil then
            return false, 'The limit given wasn\'t of type "number"!'
        end
        redis:hset('chat:' .. chat_id .. ':info', spam_type .. ' limit', tonumber(limit))
    elseif callback_query.data:match('^%-%d+:toggle:.-$') then
        local spam_type = callback_query.data:match('^%-%d+:toggle:(.-)$')
        mattata.toggle_setting(chat_id, 'allow ' .. spam_type)
    elseif callback_query.data:match('^%-%d+:disable$') then
        redis:hdel('chat:' .. chat_id .. ':settings', 'antispam')
    elseif callback_query.data:match('^%-%d+:enable$') then
        redis:hset('chat:' .. chat_id .. ':settings', 'antispam', true)
    end
    local keyboard = antispam.get_keyboard(chat_id, language)
    return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
end

function antispam.on_message(_, message, _, language)
    if message.chat.type ~= 'supergroup' then
        mattata.send_reply(message, language['errors']['supergroup'])
        return false, 'The chat is not a supergroup!'
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        mattata.send_reply(message, language['errors']['admin'])
        return false, 'That user is not an admin/mod in this chat!'
    end
    local output = string.format(language['antispam']['10'], message.chat.title)
    local keyboard = antispam.get_keyboard(message.chat.id, language)
    return mattata.send_message(message.chat.id, output, nil, true, false, nil, keyboard)
end

return antispam