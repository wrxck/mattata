--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local user = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function user:init()
    user.commands = mattata.commands(
        self.info.username
    ):command('user')
     :command('warns')
     :command('bans')
     :command('kicks')
     :command('unbans')
     :command('warnings')
     :command('status').table
    user.help = '/user [user] - Displays information about the given user.'
end

function user:on_message(message, configuration)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(
            message,
            configuration.errors.supergroup
        )
    end
    local input = message.reply and tostring(message.reply.from.id) or mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            user.help
        )
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local user = mattata.get_user(input) or mattata.get_chat(input) -- Resolve the username/ID to a user object.
    if not user then
        return mattata.send_reply(
            message,
            configuration.errors.unknown
        )
    elseif user.result.id == self.info.id then
        return
    end
    user = user.result
    local status = mattata.get_chat_member(
        message.chat.id,
        user.id
    )
    if not status then
        return mattata.send_reply(
            message,
            'I cannot display information about that user because I have never seen them in this chat.'
        )
    end
    local bans = redis:hget(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user.id
        ),
        'bans'
    ) or 0
    local kicks = redis:hget(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user.id
        ),
        'kicks'
    ) or 0
    local warnings = redis:hget(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user.id
        ),
        'warnings'
    ) or 0
    local unbans = redis:hget(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user.id
        ),
        'unbans'
    ) or 0
    local messages = redis:get('messages:' .. user.id .. ':' .. message.chat.id)
    or 0
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s [%s%s]\n\nStatus: %s\nBans: %s\nKicks: %s\nWarnings: %s\nUnbans: %s\nMessages sent: %s</pre>',
            mattata.escape_html(user.first_name),
            user.last_name and ' ' .. mattata.escape_html(user.last_name) or '',
            user.username and '@' or '',
            user.username or user.id,
            status.result.status:gsub('^%l', string.upper),
            bans,
            kicks,
            warnings,
            unbans,
            messages
        ),
        'html',
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                'Reset Warnings',
                string.format(
                    'warn:reset:%s:%s',
                    message.chat.id,
                    user.id
                )
            ):callback_data_button(
                'Remove 1 Warning',
                string.format(
                    'warn:remove:%s:%s',
                    message.chat.id,
                    user.id
                )
            )
        )
    )
end

return user