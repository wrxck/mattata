--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local administration = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')
local configuration = require('configuration')

function administration:init()
    administration.commands = mattata.commands(self.info.username):command('administration'):command('settings').table
    administration.help = '/administration [chat] - Returns the administrative settings panel for the group you it is being executed from. Optionally, group admins may edit the settings using a @mention in PM to the bot, i.e. /administration @devTalk. Alias: /settings.'
end

function administration.get_initial_keyboard(chat_id, page, language)
    if not mattata.get_setting(chat_id, 'use administration') then
        return mattata.inline_keyboard():row(mattata.row():callback_data_button(language['administration']['1'], 'administration:' .. chat_id .. ':toggle'))
    end
    if not page or tonumber(page) <= 1 then
        return mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                language['administration']['2'],
                'administration:' .. chat_id .. ':toggle'
            )
        ):row(
            mattata.row():callback_data_button(language['administration']['3'], 'antispam:' .. chat_id)
        ):row(
            mattata.row():callback_data_button(language['administration']['4'], 'administration:' .. chat_id .. ':warnings')
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['6'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'welcome message') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':welcome_message:1'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['7'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'send rules on join') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':rules_on_join:1'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['8'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'send rules in group') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':rules_in_group:1'
            )
        ):row(
            mattata.row()
            :callback_data_button(mattata.symbols.back .. ' ' .. language['administration']['9'], 'help:settings')
            :callback_data_button(language['administration']['10'] .. ' ' .. mattata.symbols.next, 'administration:' .. chat_id .. ':page:2')
        )
    elseif tonumber(page) == 2 then
        return mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(language['administration']['11'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'word filter') and 'On' or 'Off',
                'administration:' .. chat_id .. ':word_filter:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['12'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'antibot') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':antibot:2'
            )
            :callback_data_button(language['administration']['13'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'antilink') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':antilink:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['14'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'log administrative actions') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':log:2'
            )
            :callback_data_button(language['administration']['15'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'antirtl') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':rtl:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['16'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'ban not kick') and language['administration']['17'] or language['administration']['18'],
                'administration:' .. chat_id .. ':action:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['19'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'delete commands') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':delete_commands:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['20'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'force group language') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':force_group_language:2'
            )
        ):row(
            mattata.row()
            :callback_data_button(mattata.symbols.back .. ' ' .. language['administration']['9'], 'administration:' .. chat_id .. ':page:1')
            :callback_data_button(language['administration']['10'] .. ' ' .. mattata.symbols.next, 'administration:' .. chat_id .. ':page:3')
        )
    elseif tonumber(page) == 3 then
        return mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(language['administration']['21'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'settings in group') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':settings_in_group:3'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['22'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'delete reply on action') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':delete_reply_on_action:3'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['23'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'require captcha') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':require_captcha:3'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['25'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'ban spamwatch users') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':ban_spamwatch_users:4'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['46'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'remove channel pins') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':remove_channel_pins:4'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['50'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'kick media on join') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':kick_media_on_join:3'
            )
        ):row(
            mattata.row()
            :callback_data_button(mattata.symbols.back .. ' ' .. language['administration']['9'], 'administration:' .. chat_id .. ':page:2')
            :callback_data_button(language['administration']['10'] .. ' ' .. mattata.symbols.next, 'administration:' .. chat_id .. ':page:4')
        )
    elseif tonumber(page) >= 4 then
        return mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(language['administration']['47'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'remove other pins') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':remove_other_pins:4'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['48'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'remove pasted code') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':remove_pasted_code:4'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['49'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'prevent inline bots') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':prevent_inline_bots:4'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['51'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'enable plugins for admins') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':enable_plugins_for_admins:5'
            )
        ):row(
            mattata.row()
            :callback_data_button(language['administration']['52'], 'administration:nil')
            :callback_data_button(
                mattata.get_setting(chat_id, 'kick urls on join') and utf8.char(9989) or utf8.char(10060),
                'administration:' .. chat_id .. ':kick_urls_on_join:5'
            )
        ):row(
            mattata.row():callback_data_button(mattata.symbols.back .. ' ' .. language['administration']['9'], 'administration:' .. chat_id .. ':page:3')
        )
    end
    return false
end

function administration.get_warnings(chat_id, language)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    local current = mattata.get_setting(chat_id, 'max warnings') or configuration.administration.warnings.default
    local ban_kick_status = redis:get('administration:' .. chat_id .. ':ban_kick') and true or false
    local action = ban_kick_status and 'kick' or 'ban'
    local less = tonumber(current) - 1
    local more = tonumber(current) + 1
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = string.format(language['administration']['26'], action),
        ['callback_data'] = 'administration:nil'
    }})
    mattata.insert_keyboard_row(
        keyboard, '-',
        'administration:' .. chat_id .. ':max_warnings:' .. less,
        tostring(current),
        'administration:nil', '+',
        'administration:' .. chat_id .. ':max_warnings:' .. more
    )
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = language['administration']['9'],
        ['callback_data'] = 'administration:' .. chat_id .. ':page:1'
    }})
    return keyboard
end

function administration.del_chat(message, language)
    local title = message.text:match('^/chats del (.-)$')
    if not title then
        return false
    end
    for _, v in pairs(redis:smembers('mattata:configuration:chats')) do
        if not v or not json.decode(v).link or not json.decode(v).title then
            return
        elseif json.decode(v).title == title then
            redis:srem('mattata:configuration:chats', v)
            return mattata.send_reply(message, string.format(language['administration']['29'], title))
        end
    end
    return mattata.send_reply(message, string.format(language['administration']['30'], title))
end

function administration.on_callback_query(_, callback_query, message, _, language)
    if callback_query.data == 'nil' then -- An invalid callback_query payload was received, abort!
        return mattata.answer_callback_query(callback_query.id)
    elseif not mattata.is_group_admin(callback_query.data:match('^(%-%d+)'), callback_query.from.id) then
        return mattata.answer_callback_query(callback_query.id, language['administration']['31'])
    end
    local keyboard
    if callback_query.data:match('^%-%d+:warnings$') then
        local chat_id = callback_query.data:match('^(%-%d+):warnings$')
        keyboard = administration.get_warnings(chat_id, language)
    elseif callback_query.data:match('^%-%d+:max_warnings:.-$') then
        local chat_id, max_warnings = callback_query.data:match('^(%-%d+):max_warnings:(.-)$')
        if tonumber(max_warnings) > configuration.administration.warnings.maximum then
            return mattata.answer_callback_query(callback_query.id, string.format(language['administration']['36'], configuration.administration.warnings.maximum))
        elseif tonumber(max_warnings) < configuration.administration.warnings.minimum then
            return mattata.answer_callback_query(callback_query.id, string.format(language['administration']['37'], configuration.administration.warnings.minimum))
        elseif tonumber(max_warnings) == nil then
            return false
        end
        redis:hset('chat:' .. chat_id .. ':settings', 'max warnings', tonumber(max_warnings))
        keyboard = administration.get_warnings(chat_id, language)
    elseif callback_query.data:match('^%-%d+:toggle$') then
        local chat_id = callback_query.data:match('^(%-%d+):toggle$')
        mattata.toggle_setting(chat_id, 'use administration')
        keyboard = administration.get_initial_keyboard(chat_id, 1, language)
    elseif callback_query.data:match('^%-%d+:rtl:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):rtl:(%d*)$')
        mattata.toggle_setting(chat_id, 'antirtl')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:rules_on_join:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):rules_on_join:(%d*)$')
        mattata.toggle_setting(chat_id, 'send rules on join')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:rules_in_group:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):rules_in_group:(%d*)$')
        mattata.toggle_setting(chat_id, 'send rules in group')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:word_filter:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):word_filter:(%d*)$')
        mattata.toggle_setting(chat_id, 'word filter')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
        mattata.answer_callback_query(callback_query.id, language['administration']['38'], true)
    elseif callback_query.data:match('^%-%d+:inactive:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):inactive:(%d*)$')
        mattata.toggle_setting(chat_id, 'remove inactive users')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:action:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):action:(%d*)$')
        mattata.toggle_setting(chat_id, 'ban not kick')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:antibot:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):antibot:(%d*)$')
        mattata.toggle_setting(chat_id, 'antibot')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:antilink:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):antilink:(%d*)$')
        mattata.toggle_setting(chat_id, 'antilink')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:antispam:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):antispam:(%d*)$')
        mattata.toggle_setting(chat_id, 'antispam')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:welcome_message:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):welcome_message:(%d*)$')
        mattata.toggle_setting(chat_id, 'welcome message')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:delete_commands:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):delete_commands:(%d*)$')
        mattata.toggle_setting(chat_id, 'delete commands')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:misc_responses:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):misc_responses:(%d*)$')
        mattata.toggle_setting(chat_id, 'misc responses')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:force_group_language:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):force_group_language:(%d*)$')
        mattata.toggle_setting(chat_id, 'force group language')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:log:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):log:(%d*)$')
        mattata.toggle_setting(chat_id, 'log administrative actions')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:settings_in_group:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):settings_in_group:(%d*)$')
        mattata.toggle_setting(chat_id, 'settings in group')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:kick_media_on_join:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):kick_media_on_join:(%d*)$')
        mattata.toggle_setting(chat_id, 'kick media on join')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:delete_reply_on_action:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):delete_reply_on_action:(%d*)$')
        mattata.toggle_setting(chat_id, 'delete reply on action')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:require_captcha:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):require_captcha:(%d*)$')
        mattata.toggle_setting(chat_id, 'require captcha')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:ban_spamwatch_users:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):ban_spamwatch_users:(%d*)$')
        mattata.toggle_setting(chat_id, 'ban spamwatch users')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:remove_channel_pins:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):remove_channel_pins:(%d*)$')
        mattata.toggle_setting(chat_id, 'remove channel pins')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:remove_other_pins:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):remove_other_pins:(%d*)$')
        mattata.toggle_setting(chat_id, 'remove other pins')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:remove_pasted_code:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):remove_pasted_code:(%d*)$')
        mattata.toggle_setting(chat_id, 'remove pasted code')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:prevent_inline_bots:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):prevent_inline_bots:(%d*)$')
        mattata.toggle_setting(chat_id, 'prevent inline bots')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:enable_plugins_for_admins:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):enable_plugins_for_admins:(%d*)$')
        mattata.toggle_setting(chat_id, 'disable plugins for all')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:kick_urls_on_join:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):kick_urls_on_join:(%d*)$')
        mattata.toggle_setting(chat_id, 'kick urls on join')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
    elseif callback_query.data:match('^%-%d+:page:%d*$') then
        local chat_id, page = callback_query.data:match('^(%-%d+):page:(%d*)$')
        keyboard = administration.get_initial_keyboard(chat_id, page, language)
        return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
    elseif callback_query.data == 'dismiss_disabled_message' then
        redis:set('administration:' .. message.chat.id .. ':dismiss_disabled_message', true)
        return mattata.answer_callback_query(callback_query.id, language['administration']['39'], true)
    else return mattata.answer_callback_query(callback_query.id) end
    mattata.answer_callback_query(callback_query.id)
    return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
end

function administration:on_message(message, _, language)
    if message.chat.type == 'private' then
        local input = mattata.input(message.text)
        if input then
            if tonumber(input) == nil and not input:match('^@') then
                input = '@' .. input
            end
            local resolved = mattata.get_chat(input)
            if resolved and mattata.is_group_admin(resolved.result.id, message.from.id) then
                message.chat = resolved.result
                message.message_id = nil
            elseif resolved then
                return mattata.send_reply(message, language['administration']['40'])
            else
                return mattata.send_reply(message, language['administration']['41'])
            end
        else
            return mattata.send_reply(message, language['administration']['42'])
        end
    end
    if mattata.is_group_admin(message.chat.id, message.from.id) then
        local keyboard = administration.get_initial_keyboard(message.chat.id, 1, language)
        local recipient = message.from.id
        if mattata.get_setting(message.chat.id, 'settings in group') then
            recipient = message.chat.id
        end
        local output = string.format(language['administration']['43'], mattata.escape_html(message.chat.title))
        local success = mattata.send_message(recipient, output, 'html', true, false, nil, keyboard)
        if not success and recipient == message.from.id then
            return mattata.send_reply(message, string.format(language['administration']['44'], self.info.username:lower()), true)
        elseif recipient == message.from.id then
            return mattata.send_reply(message, language['administration']['45'])
        end
        return success
    end
    return false
end

return administration