--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setwelcome = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function setwelcome:init()
    setwelcome.commands = mattata.commands(
        self.info.username
    ):command('setwelcome').table
    setwelcome.help = '/setwelcome <text> - Sets the group\'s welcome message to the given, Markdown-formatted text. You can use placeholders to automatically customise the welcome message for each user. Use $user_id to insert the user\'s numerical ID, $chat_id to insert the chat\'s numerical ID, $name to insert the user\'s name, $title to insert the chat\'s title and $username to insert the user\'s username (if the user doesn\'t have an @username, their name will be used instead, so it is best to avoid using this in conjunction with $name).'
end

function setwelcome:on_message(message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            configuration.errors.admin
        )
    end
    local input = mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(
            message,
            'What would you like the welcome message to be? The text you specify will be Markdown-formatted and sent every time a user joins the chat (the welcome message can be disabled in the administration menu, accessible via /administration). You can use placeholders to automatically customise the welcome message for each user. Use $user_id to insert the user\'s numerical ID, $chat_id to insert the chat\'s numerical ID, $name to insert the user\'s name, $title to insert the chat\'s title and $username to insert the user\'s username (if the user doesn\'t have an @username, their name will be used instead, so it is best to avoid using this in conjunction with $name).'
        )
        if success then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/setwelcome'
            )
        end
        return
    end
    local validate = mattata.send_message(
        configuration.log_chat,
        input,
        'markdown'
    )
    if not validate then
        return mattata.send_reply(
            message,
            'There was an error formatting your message, please check your Markdown syntax and try again.'
        )
    end
    redis:hset(
        'chat:' .. message.chat.id .. ':values',
        'welcome message',
        input
    )
    return mattata.send_message(
        message.chat.id,
        'The welcome message for ' .. message.chat.title .. ' has successfully been updated!'
    )
end

return setwelcome