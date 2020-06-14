--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local voteban = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')

function voteban:init()
    voteban.commands = mattata.commands(self.info.username):command('voteban').table
    voteban.help = '/voteban [user] - Opens up a vote to decide if a user should be banned from the current chat. This command can only be used by moderators and administrators of a supergroup.'
end

function voteban:on_callback_query(callback_query, message, configuration, language)
    if not callback_query.data:match('^%-%d+:%d+:[yn]$')
    or not message
    then
        return mattata.answer_callback_query(
            callback_query.id,
            language['errors']['generic']
        )
    end
    local chat_id, user_id, vote = callback_query.data:match('^(%-%d+):(%d+):([yn])$')
    local current_upvote = tonumber(
        redis:hget(
            'voteban:' .. chat_id .. ':' .. user_id,
            'y'
        )
    )
    local current_downvote = tonumber(
        redis:hget(
            'voteban:' .. chat_id .. ':' .. user_id,
            'n'
        )
    )
    local user_object = json.decode(
        redis:hget(
            'voteban:' .. chat_id .. ':' .. user_id,
            'user_object'
        )
    )
    local required_upvotes = tonumber(
        redis:hget(
            'chat:' .. chat_id .. ':settings',
            'required upvotes for vote bans'
        )
    )
    or configuration.administration.voteban.upvotes.default
    local required_downvotes = tonumber(
        redis:hget(
            'chat:' .. chat_id .. ':settings',
            'required downvotes for vote bans'
        )
    )
    or configuration.administration.voteban.downvotes.default
    if redis:hget(
        'voteban:' .. chat_id .. ':' .. user_id,
        callback_query.from.id
    )
    then
        local current_vote = redis:hget(
            'voteban:' .. chat_id .. ':' .. user_id,
            callback_query.from.id
        )
        if current_vote == 'y'
        then
            current_upvote = current_upvote - 1
        else
            current_downvote = current_downvote - 1
        end
        redis:hdel(
            'voteban:' .. chat_id .. ':' .. user_id,
            callback_query.from.id
        )
        redis:hincrby(
            'voteban:' .. chat_id .. ':' .. user_id,
            current_vote,
            -1
        )
        mattata.answer_callback_query(
            callback_query.id,
            language['voteban']['11']
        )
    elseif vote == 'y'
    then
        current_upvote = current_upvote + 1
        redis:hset(
            'voteban:' .. chat_id .. ':' .. user_id,
            callback_query.from.id,
            'y'
        )
        if current_upvote >= required_upvotes
        then
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'y'
            )
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'n'
            )
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'user_object'
            )
            local success = mattata.ban_chat_member(
                chat_id,
                user_id
            )
            local output = string.format(
                language['voteban']['7'],
                user_object.first_name,
                user_object.id,
                message.chat.title,
                current_upvote
            )
            if not success
            then -- If the ban failed, then we're going to need an error message, rather than
            -- a message suggesting the ban was a success!
                output = string.format(
                    language['voteban']['8'],
                    user_object.first_name
                )
            else
                redis:hdel(
                    'voteban:' .. chat_id .. ':' .. user_id,
                    'user_object'
                )
                redis:hdel(
                    'voteban:' .. chat_id .. ':' .. user_id,
                    'y'
                )
                redis:hdel(
                    'voteban:' .. chat_id .. ':' .. user_id,
                    'n'
                )
            end
            return mattata.edit_message_text(
                chat_id,
                message.message_id,
                output
            )
        end
        redis:hincrby(
            'voteban:' .. chat_id .. ':' .. user_id,
            'y',
            1
        )
        mattata.answer_callback_query(
            callback_query.id,
            string.format(
                language['voteban']['10'],
                user_object.first_name,
                user_object.id
            )
        )
    else
        redis:hset(
            'voteban:' .. chat_id .. ':' .. user_id,
            callback_query.from.id,
            'n'
        )
        current_downvote = current_downvote + 1
        if current_downvote >= required_downvotes
        then
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'y'
            )
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'n'
            )
            redis:hdel(
                'voteban:' .. chat_id .. ':' .. user_id,
                'user_object'
            )
            return mattata.edit_message_text(
                chat_id,
                message.message_id,
                string.format(
                    language['voteban']['9'],
                    user_object.first_name,
                    user_object.id,
                    message.chat.title,
                    current_downvote
                )
            )
        end
        redis:hincrby(
            'voteban:' .. chat_id .. ':' .. user_id,
            'n',
            1
        )
        mattata.answer_callback_query(
            callback_query.id,
            string.format(
                language['voteban']['12'],
                user_object.first_name,
                user_object.id
            )
        )
    end
    return mattata.edit_message_reply_markup(
        chat_id,
        message.message_id,
        nil,
        mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(
                string.format(
                    language['voteban']['5'],
                    tostring(current_upvote)
                ),
                'voteban:' .. message.chat.id .. ':' .. user_object.id .. ':y'
            )
            :callback_data_button(
                string.format(
                    language['voteban']['6'],
                    tostring(current_downvote)
                ),
                'voteban:' .. message.chat.id .. ':' .. user_object.id .. ':n'
            )
        )
    )
end

function voteban:on_message(message, configuration, language)
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
    local input = mattata.input(message)
    -- Check the message object for any users this command
    -- is intended to be executed on.
    if message.reply
    and not input
    then
        user = message.reply.from.id
    elseif message.reply
    and not input:match(' ')
    then
        user = input
    elseif message.reply
    then
        user, reason = input:match('^(.-) (.-)$')
    elseif input
    and not input:match(' ')
    then
        user = input
    elseif input
    then
        user, reason = input:match('^(.-) (.-)$')
    end
    if not user
    then
        local success = mattata.send_force_reply(
            message,
            language['voteban']['1']
        )
        if success
        then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/voteban'
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
    then -- We won't try and open up votes to ban moderators and administrators.
        return mattata.send_reply(
            message,
            language['voteban']['2']
        )
    elseif status.result.status == 'left'
    or status.result.status == 'kicked'
    then -- Check if the user is in the group or not.
        return mattata.send_reply(
            message,
            language['voteban']['3']
        )
    elseif redis:hexists(
        'voteban:' .. message.chat.id .. ':' .. user_object.id,
        'user_object'
    )
    then
        return mattata.send_reply(
            message,
            language['voteban']['13']
        )
    end
    redis:hset(
        'voteban:' .. message.chat.id .. ':' .. user_object.id,
        'user_object',
        json.encode(user_object)
    )
    redis:hset(
        'voteban:' .. message.chat.id .. ':' .. user_object.id,
        'y',
        0
    )
    redis:hset(
        'voteban:' .. message.chat.id .. ':' .. user_object.id,
        'n',
        0
    )
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['voteban']['4'],
            user_object.username
            and '@' .. user_object.username
            or user_object.first_name,
            user_object.id,
            message.chat.title,
            redis:hget(
                'chat:' .. message.chat.id .. ':settings',
                'required upvotes for vote bans'
            )
            or '5',
            redis:hget(
                'chat:' .. message.chat.id .. ':settings',
                'required downvotes for vote bans'
            )
            or '5'
        ),
        nil,
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row()
            :callback_data_button(
                string.format(
                    language['voteban']['5'],
                    '0'
                ),
                'voteban:' .. message.chat.id .. ':' .. user_object.id .. ':y'
            )
            :callback_data_button(
                string.format(
                    language['voteban']['6'],
                    '0'
                ),
                'voteban:' .. message.chat.id .. ':' .. user_object.id .. ':n'
            )
        )
    )
end

return voteban