--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local trust = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function trust:init()
    trust.commands = mattata.commands(self.info.username):command('trust').table
    trust.help = '/trust [user] - Promotes a user to a trusted user of the current chat. This command can only be used by administrators of a supergroup.'
end

function trust:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id,
        true
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    end
    local input = message.reply
    and tostring(message.reply.from.id)
    or mattata.input(message)
    if not input
    then
        return mattata.send_reply(
            message,
            trust.help
        )
    end
    if tonumber(input) == nil
    and not input:match('^%@')
    then
        input = '@' .. input
    end
    local user = mattata.get_user(input)
    or mattata.get_chat(input) -- Resolve the username/ID to a user object.
    if not user
    then
        return mattata.send_reply(
            message,
            language['errors']['unknown']
        )
    elseif user.result.id == self.info.id
    then
        return
    end
    user = user.result
    local status = mattata.get_chat_member(
        message.chat.id,
        user.id
    )
    if not status
    then
        return mattata.send_reply(
            message,
            language['errors']['generic']
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        user.id
    )
    or status.result.status == 'creator'
    or status.result.status == 'administrator'
    then -- We won't try and trust moderators and administrators.
        return mattata.send_reply(
            message,
            language['trust']['1']
        )
    elseif status.result.status == 'left'
    or status.result.status == 'kicked'
    then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            status.result.status == 'left'
            and language['trust']['2']
            or language['trust']['3']
        )
    end
    redis:sadd(
        'administration:' .. message.chat.id .. ':trusted',
        user.id
    )
    if redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'log administrative actions'
    )
    then
        mattata.send_message(
            mattata.get_log_chat(message.chat.id),
            string.format(
                '<pre>%s%s [%s] has trusted %s%s [%s] in %s%s [%s].</pre>',
                message.from.username
                and '@'
                or '',
                message.from.username
                or mattata.escape_html(message.from.first_name),
                message.from.id,
                user.username
                and '@'
                or '',
                user.username
                or mattata.escape_html(user.first_name),
                user.id,
                message.chat.username
                and '@'
                or '',
                message.chat.username
                or mattata.escape_html(message.chat.title),
                message.chat.id
            ),
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s has trusted %s%s.</pre>',
            message.from.username
            and '@'
            or '',
            message.from.username
            or mattata.escape_html(message.from.first_name),
            user.username
            and '@'
            or '',
            user.username
            or mattata.escape_html(user.first_name)
        ),
        'html'
    )
end

return trust