--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ban = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function ban:init()
    ban.commands = mattata.commands(
        self.info.username
    ):command('ban').table
    ban.help = '/ban [user] - Bans a user from the current chat. This command can only be used by moderators and administrators of a supergroup.'
end

function ban:on_message(message, configuration)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(
            message,
            configuration.errors.supergroup
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            configuration.errors.admin
        )
    end
    local reason = false
    local input = message.reply and tostring(message.reply.from.id) or mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            ban.help
        )
    elseif not message.reply and input:match('^%@?%w+ ') then
        reason = input:match('^%@?%w+ (.-)$')
        input = input:match('^(%@?%w+) ')
    elseif mattata.input(message.text) then
        reason = mattata.input(message.text)
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
            configuration.errors.generic
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        user.id
    ) or status.result.status == 'creator' or status.result.status == 'administrator' then -- We won't try and ban moderators and administrators.
        return mattata.send_reply(
            message,
            'I cannot ban this user because they are a moderator or an administrator in this chat.'
        )
    elseif status.result.status == 'left' or status.result.status == 'kicked' then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            string.format(
                'I cannot ban this user because they have already %s this chat.',
                (status.result.status == 'left' and 'left') or (status.result.status == 'kicked' and 'been banned from')
            )
        )
    end
    local success = mattata.ban_chat_member( -- Attempt to ban the user from the group.
        message.chat.id,
        user.id
    )
    if not success then -- Since we've ruled everything else out, it's safe to say if it wasn't a success then the bot isn't an administrator in the group.
        return mattata.send_reply(
            message,
            'I need to have administrative permissions in order to ban this user. Please amend this issue, and try again.'
        )
    end
    redis:hincrby(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user.id
        ),
        'bans',
        1
    )
    if redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'log administrative actions'
    ) then
        mattata.send_message(
            configuration.admin_log_chat or configuration.admins[1],
            string.format(
                '<pre>%s%s [%s] has banned %s%s [%s] from %s%s [%s]%s.</pre>',
                message.from.username and '@' or '',
                message.from.username or mattata.escape_html(message.from.first_name),
                message.from.id,
                user.username and '@' or '',
                user.username or mattata.escape_html(user.first_name),
                user.id,
                message.chat.username and '@' or '',
                message.chat.username or mattata.escape_html(message.chat.title),
                message.chat.id,
                reason and ', for ' .. reason or ''
            ),
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s has banned %s%s%s.</pre>',
            message.from.username and '@' or '',
            message.from.username or mattata.escape_html(message.from.first_name),
            user.username and '@' or '',
            user.username or mattata.escape_html(user.first_name),
            reason and ', for ' .. reason or ''
        ),
        'html'
    )
end

return ban