--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local antibot = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function antibot:process_message(message, configuration, language)
    if mattata.get_setting(
        message.chat.id,
        'use administration'
    )
    and mattata.get_setting(
        message.chat.id,
        'antibot'
    )
    and message.chat.type == 'supergroup'
    and not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    and message.new_chat_member
    and message.new_chat_member.username
    and message.new_chat_member.username:lower():match('bot$')
    and message.new_chat_member.id ~= message.from.id
    then
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.new_chat_member.id
        )
        if success
        then
            mattata.send_message(
                mattata.get_log_chat(message.chat.id),
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
            return mattata.send_message(
                message,
                string.format(
                    'Kicked @%s because anti-bot is enabled.',
                    message.new_chat_member.username
                )
            )
        end
    end
    return false
end

return antibot