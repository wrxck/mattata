--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local demote = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function demote:init()
    demote.commands = mattata.commands(
        self.info.username
    ):command('demote')
     :command('demod').table
    demote.help = '/demote [user] - Demotes a user to a standard user of the current chat. This command can only be used by administrators of a supergroup. Alias: /demod.'
end

function demote:on_message(message, configuration)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(
            message,
            configuration.errors.supergroup
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    ) then
        return mattata.send_reply(
            message,
            configuration.errors.admin
        )
    end
    local input = message.reply and tostring(message.reply.from.id) or mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            demote.help
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
            configuration.errors.generic
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        user.id
    ) then -- We won't try and demote users who aren't moderators/administrators.
        return mattata.send_reply(
            message,
            'I cannot demote this user because they are not a moderator or an administrator in this chat.'
        )
    elseif status.result.status == 'left' or status.result.status == 'kicked' then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            string.format(
                'I cannot demote this user because they have already %s this chat.',
                (status.result.status == 'left' and 'left') or (status.result.status == 'kicked' and 'been kicked from')
            )
        )
    end
    redis:del(
        string.format(
            'mod:%s:%s',
            message.chat.id,
            user.id
        )
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
                '<pre>%s%s [%s] has demoted %s%s [%s] in %s%s [%s].</pre>',
                message.from.username and '@' or '',
                message.from.username or mattata.escape_html(message.from.first_name),
                message.from.id,
                user.username and '@' or '',
                user.username or mattata.escape_html(user.first_name),
                user.id,
                message.chat.username and '@' or '',
                message.chat.username or mattata.escape_html(message.chat.title),
                message.chat.id
            ),
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s has demoted %s%s.</pre>',
            message.from.username and '@' or '',
            message.from.username or mattata.escape_html(message.from.first_name),
            user.username and '@' or '',
            user.username or mattata.escape_html(user.first_name)
        ),
        'html'
    )
end

return demote