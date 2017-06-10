--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local welcome = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function welcome:process_message(message, configuration, language)
    if not message.new_chat_member
    or message.chat.type == 'private'
    or not mattata.get_setting(
        message.chat.id,
        'use administration'
    )
    or not mattata.get_setting(
        message.chat.id,
        'welcome message'
    )
    then
        return false
    end
    local name = message.new_chat_member.first_name
    local first_name = mattata.escape_markdown(name)
    if message.new_chat_member.last_name
    then
        name = name .. ' ' .. message.new_chat_member.last_name
    end
    name = name:gsub('%%', '%%%%')
    name = mattata.escape_markdown(name)
    local title = message.chat.title:gsub('%%', '%%%%')
    title = mattata.escape_markdown(title)
    local username = message.new_chat_member.username
    and '@' .. message.new_chat_member.username
    or name
    local welcome_message = mattata.get_value(
        message.chat.id,
        'welcome message'
    )
    or configuration.join_messages
    if type(welcome_message) == 'table'
    then
        welcome_message = welcome_message[math.random(#welcome_message)]:gsub('NAME', name)
    end
    welcome_message = welcome_message
    :gsub('%$user_id', message.new_chat_member.id)
    :gsub('%$chat_id', message.chat.id)
    :gsub('%$first_name', first_name)
    :gsub('%$name', name)
    :gsub('%$title', title)
    :gsub('%$username', username)
    local keyboard
    if mattata.get_setting(
        message.chat.id,
        'send rules on join'
    )
    then
        keyboard = mattata.inline_keyboard():row(
            mattata.row():url_button(
                utf8.char(128218) .. ' ' .. language['welcome']['1'],
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

return welcome