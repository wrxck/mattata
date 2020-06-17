--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setcaptcha = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function setcaptcha:init()
    setcaptcha.commands = mattata.commands(self.info.username):command('setcaptcha').table
    setcaptcha.help = '/setcaptcha - Allows admins to configure CAPTCHA settings.'
end

function setcaptcha.on_callback_query(_, callback_query, message, configuration, language)
    local action, new, chat_id = callback_query.data:match('^(.-):(.-):(.-)$')
    if not action or not new or not chat_id then
        return mattata.answer_callback_query(callback_query.id)
    elseif not mattata.is_group_admin(chat_id, callback_query.from.id) then
        return mattata.answer_callback_query(callback_query.id, language.errors.admin)
    end
    new = tonumber(new)
    local captchas = configuration.administration.captcha.files
    local length = mattata.get_setting(chat_id, 'captcha length') or configuration.administration.captcha.length.default
    length = math.floor(length)
    local next_length = length + 1
    local prev_length = length - 1
    local size = mattata.get_setting(chat_id, 'captcha size') or configuration.administration.captcha.size.default
    size = math.floor(size)
    local next_size = size + 1
    local prev_size = size - 1
    local current = mattata.get_setting(chat_id, 'captcha font') or 1
    current = math.floor(current)
    local font_name = captchas[current] or captchas[1]
    local next_font_pos = current + 1
    local prev_font_pos = current - 1
    if action == 'font' then
        if tonumber(new) < 1 then
            new = #captchas
        elseif tonumber(new) > #captchas then
            new = 1
        end
        font_name = captchas[new]
        if not font_name then
            return mattata.answer_callback_query(callback_query.from.id, 'This font is no longer available!')
        end
        redis:hset('chat:' .. chat_id .. ':settings', 'captcha font', new)
        if next_font_pos > #captchas then
            next_font_pos = 1
        end
        prev_font_pos = new - 1
        if prev_font_pos < 1 then
            prev_font_pos = #captchas
        end
    elseif action == 'length' then
        if tonumber(new) < configuration.administration.captcha.length.min then
            new = configuration.administration.captcha.length.max
        elseif tonumber(new) > configuration.administration.captcha.length.max then
            new = configuration.administration.captcha.length.min
        end
        redis:hset('chat:' .. chat_id .. ':settings', 'captcha length', new)
        length = new
        next_length = new + 1
        if next_length > configuration.administration.captcha.length.max then
            next_length = configuration.administration.captcha.length.min
        end
        prev_length = new - 1
        if prev_length < configuration.administration.captcha.length.min then
            prev_length = configuration.administration.captcha.length.max
        end
    elseif action == 'size' then
        if tonumber(new) < configuration.administration.captcha.size.min then
            new = configuration.administration.captcha.size.max
        elseif tonumber(new) > configuration.administration.captcha.size.max then
            new = configuration.administration.captcha.size.min
        end
        redis:hset('chat:' .. chat_id .. ':settings', 'captcha size', new)
        size = new
        next_size = new + 1
        if next_size > configuration.administration.captcha.size.max then
            next_size = configuration.administration.captcha.size.min
        end
        prev_size = new - 1
        if prev_size < configuration.administration.captcha.size.min then
            prev_size = configuration.administration.captcha.size.max
        end
    end
    font_name = font_name:gsub('^%l', string.upper):gsub('%.[to]tf$', '')
    local keyboard = mattata.inline_keyboard():row(
        mattata.row():callback_data_button('CAPTCHA Length', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:length:' .. prev_length .. ':' .. chat_id)
        :callback_data_button(length, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:length:' .. next_length .. ':' .. chat_id)
    ):row(
        mattata.row():callback_data_button('Font Size', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:size:' .. prev_size .. ':' .. chat_id)
        :callback_data_button(size, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:size:' .. next_size .. ':' .. chat_id)
    ):row(
        mattata.row():callback_data_button('Font Family', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:font:' .. prev_font_pos .. ':' .. chat_id)
        :callback_data_button(font_name, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:font:' .. next_font_pos .. ':' .. chat_id)
    ):row(
        mattata.row():callback_data_button('Done', 'dismiss')
    )
    return mattata.edit_message_reply_markup(message.chat.id, message.message_id, nil, keyboard)
end

function setcaptcha:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local captcha = configuration.administration.captcha
    local length = mattata.get_setting(message.chat.id, 'captcha length') or configuration.administration.captcha.length.default
    length = math.floor(length)
    local next_length = length + 1
    local prev_length = length - 1
    local size = mattata.get_setting(message.chat.id, 'captcha size') or configuration.administration.captcha.size.default
    size = math.floor(size)
    local next_size = size + 1
    local prev_size = size - 1
    local font_file = mattata.get_setting(message.chat.id, 'captcha font') or 1
    font_file = math.floor(font_file)
    local font_name = configuration.administration.captcha.files[tonumber(font_file)]
    font_name = font_name:gsub('^%l', string.upper):gsub('%.[to]tf$', '')
    local font_pos = 1
    for pos, font in pairs(captcha.files) do
        if font == font_file then
            font_pos = pos
        end
    end
    local next_font_pos = font_pos + 1
    if next_font_pos > #captcha.files then
        next_font_pos = 1
    end
    local prev_font_pos = font_pos - 1
    if prev_font_pos < 1 then
        prev_font_pos = #captcha.files
    end
    local keyboard = mattata.inline_keyboard():row(
        mattata.row():callback_data_button('CAPTCHA Length', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:length:' .. prev_length .. ':' .. message.chat.id)
        :callback_data_button(length, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:length:' .. next_length .. ':' .. message.chat.id)
    ):row(
        mattata.row():callback_data_button('Font Size', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:size:' .. prev_size .. ':' .. message.chat.id)
        :callback_data_button(size, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:size:' .. next_size .. ':' .. message.chat.id)
    ):row(
        mattata.row():callback_data_button('Font Family', 'setcaptcha')
    ):row(
        mattata.row()
        :callback_data_button(utf8.char(11013), 'setcaptcha:font:' .. prev_font_pos .. ':' .. message.chat.id)
        :callback_data_button(font_name, 'setcaptcha')
        :callback_data_button(utf8.char(10145), 'setcaptcha:font:' .. next_font_pos .. ':' .. message.chat.id)
    ):row(
        mattata.row():callback_data_button('Done', 'dismiss')
    )
    local output = 'Use the keyboard below to adjust the CAPTCHA settings in <b>%s</b>:'
    output = string.format(output, mattata.escape_html(message.chat.title))
    if mattata.get_setting(message.chat.id, 'settings in group') then
        return mattata.send_message(message.chat.id, output, 'html', true, false, nil, keyboard)
    else
        local success = mattata.send_message(message.from.id, output, 'html', true, false, nil, keyboard)
        if not success then
            return mattata.send_reply(message, 'You need to [private message me](https://t.me/' .. self.info.username:lower() .. ') before I can send you this!', true, true)
        end
        return mattata.send_reply(message, 'I\'ve sent you the CAPTCHA configuration panel [via private message](https://t.me/' .. self.info.username:lower() .. ')!', true, true)
    end
end

return setcaptcha