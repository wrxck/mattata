--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local join_captcha = {}
local mattata = require('mattata')
local redis = require('libs.redis')
local captcha_lib = require('captcha')

function join_captcha:cron()
    local keys = redis:keys('chat:*:captcha:*')
    for _, key in pairs(keys) do
        local chat_id, user_id = key:match('^chat:(%-?%d+):captcha:(%d+)$')
        if not redis:get('captcha:' .. chat_id .. ':' .. user_id) then
            local message_id = redis:hget(key, 'id')
            mattata.delete_message(chat_id, message_id)
            local user = mattata.get_user(user_id, nil, nil, true)
            local kicked_user = mattata.get_formatted_user(user_id, user.result.first_name, 'html')
            local action = mattata.get_setting(chat_id, 'ban not kick')
            local punishment = action and 'Banned' or 'Kicked'
            if punishment == 'Banned' then
                action = mattata.ban_chat_member
            else action = mattata.kick_chat_member end
            local success = action(chat_id, user_id)
            if not success then
                mattata.wipe_redis_captcha(chat_id, user_id)
            else
                local output = punishment .. ' ' .. kicked_user .. ' <code>[' .. user_id .. ']</code> %sbecause they didn\'t complete the CAPTCHA within 5 minutes!'
                if mattata.get_setting(chat_id, 'log administrative actions') then
                    local chat = mattata.get_chat(chat_id)
                    local log_output = output
                    if chat then
                        local title = mattata.escape_html(chat.result.title)
                        title = 'from ' .. title .. ' <code>[' .. chat.result.id .. ']</code> '
                        log_output = string.format(log_output, title)
                        log_output = log_output .. '\n#chat' .. tostring(chat.result.id):gsub('^%-100', '') .. ' #user' .. user_id
                    else
                        log_output = string.format(log_output, '')
                    end
                    mattata.send_message(mattata.get_log_chat(chat_id), log_output, 'html')
                else
                    output = string.format(output, '')
                    mattata.send_message(chat_id, output, 'html')
                end
                mattata.wipe_redis_captcha(chat_id, user_id)
            end
        end
    end
end

function join_captcha.on_callback_query(_, callback_query, message)
    if not callback_query.data:match('^.-:.-:.-$') then
        return false
    end
    local chat_id, user_id, guess = callback_query.data:match('^(.-):(.-):(.-)$')
    if callback_query.from.id ~= tonumber(user_id) then
        return mattata.answer_callback_query(callback_query.id, 'This isn\'t your CAPTCHA!')
    end
    local correct = mattata.get_captcha_text(chat_id, callback_query.from.id)
    local message_id = mattata.get_captcha_id(chat_id, callback_query.from.id)
    local default_permissions = mattata.get_chat(message.chat.id)
    if guess:lower() == correct:lower() then
        local success
        if not default_permissions then
            success = mattata.restrict_chat_member(chat_id, callback_query.from.id, 'forever', true, true, true, true, true, false, false, false)
        else
            success = mattata.restrict_chat_member(chat_id, callback_query.from.id, 'forever', default_permissions.result.permissions)
        end
        if not success then
            return mattata.send_message(message.chat.id, 'I could not give a user their permissions. You may have to do this manually!')
        end
        mattata.wipe_redis_captcha(chat_id, callback_query.from.id)
        mattata.answer_callback_query(callback_query.id, 'Success! You may now speak!')
        return mattata.delete_message(chat_id, message_id)
    else
        if mattata.get_setting(chat_id, 'log administrative actions') then
            local failed_username = mattata.get_formatted_user(callback_query.from.id, callback_query.from.first_name, 'html')
            local chat_title = mattata.escape_html(message.chat.title)
            local output = '%s <code>[%s]</code> failed the CAPTCHA in %s <code>[%s]</code>. They guessed <code>%s</code> but the correct answer was <code>%s</code>.\n#chat%s #user%s'
            output = string.format(output, failed_username, user_id, chat_title, chat_id, guess, correct, tostring(chat_id):gsub('^%-100', ''), user_id)
            local log_chat = mattata.get_log_chat(chat_id)
            mattata.send_message(log_chat, output, 'html')
        end
        mattata.wipe_redis_captcha(chat_id, callback_query.from.id)
        mattata.answer_callback_query(callback_query.id, 'You got it wrong! Re-join the group and try again, or consult an admin if you wish to be unmuted!')
        return mattata.delete_message(chat_id, message_id)
    end
end

function join_captcha.on_member_join(_, message, configuration)
    if mattata.get_setting(message.chat.id, 'require captcha') and not message.new_chat_participant.is_bot then
        if mattata.get_captcha_id(message.chat.id, message.new_chat_participant.id) then
            return mattata.send_reply(message, 'You still need to complete your CAPTCHA in order to speak!')
        end
        local chat_member = mattata.get_chat_member(message.chat.id, message.new_chat_participant.id)
        if not chat_member then -- we can't even get info about the user? abort! abort!
            return false
        end
        local download_location = configuration.download_location
        if download_location:match('/$') then
            download_location = download_location:match('^(.-)/$')
        end
        local new_captcha = captcha_lib.new()
        new_captcha:setlength(7)
        new_captcha:setfontsize(45)
        new_captcha:setpath(download_location)
        new_captcha:setformat('jpg')
        new_captcha:setfontsfolder(configuration.fonts_directory)
        local generated_captcha = new_captcha:generate()
        local username = message.new_chat_participant.username and '@' .. message.new_chat_participant.username or false
        local msg = string.format('Hey, [%s](tg://user?id=%s)! Please enter the above CAPTCHA using the buttons below before you can speak! You will be removed in 5 minutes if you don\'t do this.', username or mattata.escape_markdown(message.new_chat_participant.first_name), message.new_chat_participant.id)
        local correct = generated_captcha:match('^' .. download_location .. '/(.-)%.jpg$')
        local captchas = mattata.random_string(8, 5)
        table.insert(captchas, correct)
        table.sort(captchas)
        local callback_data = string.format('join_captcha:%s:%s', message.chat.id, message.new_chat_participant.id)
        local keyboard = mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(captchas[1], callback_data .. ':' .. captchas[1])
            :callback_data_button(captchas[2], callback_data .. ':' .. captchas[2])
            :callback_data_button(captchas[3], callback_data .. ':' .. captchas[3])
        ):row(
            mattata.row()
            :callback_data_button(captchas[4], callback_data .. ':' .. captchas[4])
            :callback_data_button(captchas[5], callback_data .. ':' .. captchas[5])
            :callback_data_button(captchas[6], callback_data .. ':' .. captchas[6])
        )
        local success = mattata.send_photo(message.chat.id, generated_captcha, msg, 'markdown', false, nil, keyboard)
        if not success then
            error('No success!')
            os.execute('rm ' .. generated_captcha)
            return false
        end
        os.execute('rm ' .. generated_captcha)
        local restrict = mattata.restrict_chat_member(message.chat.id, message.new_chat_participant.id, 'forever', false, false, false, false, false, false, false, false)
        if restrict then
            mattata.set_captcha(message.chat.id, message.new_chat_participant.id, correct, success.result.message_id)
            mattata.delete_message(message.chat.id, message.message_id)
        else
            error('Could not restrict ChatMember!')
        end
        return
    end
end

return join_captcha