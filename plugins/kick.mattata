--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local kick = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function kick:init()
    kick.commands = mattata.commands(self.info.username):command('kick').table
    kick.help = '/kick [user] - Kicks a user from the current chat. This command can only be used by moderators and administrators of a supergroup.'
end

function kick:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    end
    local reason = false
    local user = false
    local input = mattata.input(message.text)
    -- Check the message object for any users this command
    -- is intended to be executed on.
    if message.reply
    then
        user = message.reply.from.id
        if input
        then
            reason = input
        end
    elseif input
    and input:match(' ')
    then
        user, reason = input:match('^(.-) (.-)$')
    elseif input
    then
        user = input
    end
    if not user
    then
        local success = mattata.send_force_reply(
            message,
            language['kick']['1']
        )
        if success
        then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/kick'
            )
        end
        return
    end
    if reason
    and type(reason) == 'string'
    and reason:match('^[Ff][Oo][Rr] ')
    then
        reason = reason:match('^[Ff][Oo][Rr] (.-)$')
    end
    if tonumber(user) == nil
    and not user:match('^%@')
    then
        user = '@' .. user
    end
    local user_object = mattata.get_user(user)
    or mattata.get_chat(user) -- Resolve the username/ID to a user object.
    if not user_object
    then
        return mattata.send_reply(
            message,
            language['errors']['unknown']
        )
    elseif user_object.result.id == self.info.id
    then
        return
    end
    user_object = user_object.result
    local status = mattata.get_chat_member(
        message.chat.id,
        user_object.id
    )
    if not status
    then
        return mattata.send_reply(
            message,
            language['errors']['generic']
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        user_object.id
    )
    or status.result.status == 'creator'
    or status.result.status == 'administrator'
    then -- We won't try and kick moderators and administrators.
        return mattata.send_reply(
            message,
            language['kick']['2']
        )
    elseif status.result.status == 'left'
    or status.result.status == 'kicked'
    then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            status.result.status == 'left'
            and language['kick']['3']
            or language['kick']['4']
        )
    end
    local success = mattata.kick_chat_member( -- Attempt to kick the user from the group.
        message.chat.id,
        user_object.id
    )
    if not success
    then -- Since we've ruled everything else out, it's safe to say if it wasn't a success
    -- then the bot isn't an administrator in the group.
        return mattata.send_reply(
            message,
            language['kick']['5']
        )
    end
    redis:hincrby(
        string.format(
            'chat:%s:%s',
            message.chat.id,
            user_object.id
        ),
        'kicks',
        1
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
                '<pre>%s%s [%s] has kicked %s%s [%s] from %s%s [%s]%s.</pre>',
                message.from.username
                and '@'
                or '',
                message.from.username
                or mattata.escape_html(message.from.first_name),
                message.from.id,
                user_object.username
                and '@'
                or '',
                user_object.username
                or mattata.escape_html(user_object.first_name),
                user_object.id,
                message.chat.username
                and '@'
                or '',
                message.chat.username
                or mattata.escape_html(message.chat.title),
                message.chat.id,
                reason
                and ', for ' .. reason
                or ''
            ),
            'html'
        )
    end
    if message.reply
    and mattata.get_setting(
        message.chat.id,
        'delete reply on action'
    )
    then
        mattata.delete_message(
            message.chat.id,
            message.reply.message_id
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s%s has kicked %s%s%s.</pre>',
            message.from.username
            and '@'
            or '',
            message.from.username
            or mattata.escape_html(message.from.first_name),
            user_object.username
            and '@'
            or '',
            user_object.username
            or mattata.escape_html(user_object.first_name),
            reason
            and ', for ' .. reason
            or ''
        ),
        'html'
    )
end

return kick