--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local restrict = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function restrict:init()
    restrict.commands = mattata.commands(self.info.username):command('restrict').table
    restrict.help = '/restrict [user] - Adjust what types of media a user can send in the chat. The user may be specified by username, ID or by replying to one of their messages.'
end

function restrict.get_keyboard(chat_id, user_id)
    return mattata.inline_keyboard()
    :row(
        mattata.row()
        :callback_data_button(
            'Messages',
            'restrict:nil'
        )
        :callback_data_button(
            mattata.get_user_setting(
                chat_id,
                user_id,
                'restrict messages'
            )
            and 'No'
            or 'Yes',
            'restrict:messages:' .. chat_id .. ':' .. user_id
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Media Messages',
            'restrict:nil'
        )
        :callback_data_button(
            mattata.get_user_setting(
                chat_id,
                user_id,
                'restrict media messages'
            )
            and 'No'
            or 'Yes',
            'restrict:media_messages:' .. chat_id .. ':' .. user_id
        )
    )
    :row(
        mattata.row()
        :callback_data_button(
            'Other Messages',
            'restrict:nil'
        )
        :callback_data_button(
            mattata.get_user_setting(
                chat_id,
                user_id,
                'restrict other messages'
            )
            and 'No'
            or 'Yes',
            'restrict:other_messages:' .. chat_id .. ':' .. user_id
        )
    )
end

function restrict:on_callback_query(callback_query, message, configuration, language)
    if callback_query.data == 'nil'
    or not callback_query.data:match('^[%a_]+:%-?%d+:%d+$')
    then
        return mattata.answer_callback_query(callback_query.id)
    end
    local message_type, chat_id, user_id = callback_query.data:match('^([%a_]+):(%-?%d+):(%d+)$')
    if not mattata.is_group_admin(
        chat_id,
        callback_query.from.id
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'You\'re not an administrator in this chat!',
            true
        )
    elseif not mattata.is_group_admin(
        chat_id,
        self.info.id,
        true
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'I need to have administrative permissions to restrict this user!',
            true
        )
    elseif mattata.is_group_admin(
        chat_id,
        user_id
    )
    then
        return mattata.answer_callback_query(
            callback_query.id,
            'That user appears to have been granted administrative permissions since the keyboard was sent!',
            true
        )
    end
    mattata.toggle_user_setting(
        chat_id,
        user_id,
        'restrict ' .. message_type:gsub('_', ' ')
    )
    return mattata.edit_message_reply_markup(
        message.chat.id,
        message.message_id,
        nil,
        restrict.get_keyboard(
            chat_id,
            user_id
        )
    )
end

function restrict:on_message(message, configuration, language)
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
    elseif not mattata.is_group_admin(
        message.chat.id,
        self.info.id,
        true
    )
    then
        return mattata.send_reply(
            message,
            'I need to have administrative permissions to restrict this user!'
        )
    end
    local input = mattata.input(message.text)
    local user = input
    if not input
    or message.reply
    then
        if not message.reply
        then
            return mattata.send_reply(
                message,
                restrict.help
            )
        end
        user = message.reply.from
    else
        if tonumber(user) == nil
        and not user:match('^@')
        then
            user = '@' .. user
        end
        user = mattata.get_user(user)
        if user
        then
            user = user.result
        end
    end
    if type(user) ~= 'table'
    then
        return mattata.send_reply(
            message,
            'Sorry, but I don\'t recognise this user! If you\'d like to teach me who they are, please forward a message from them to me.'
        )
    end
    user = mattata.get_chat_member(
        message.chat.id,
        user.id
    )
    if not user
    or type(user) ~= 'table'
    or not user.result
    or not user.result.user
    or not user.result.status
    or user.result.status == 'kicked'
    or user.result.status == 'left'
    then
        return mattata.send_reply(
            message,
            'Are you sure you specified the correct user? They do not appear to be a member of this chat.'
        )
    end
    user = user.result.user
    if mattata.is_group_admin(
        message.chat.id,
        user.id
    )
    then
        return mattata.send_reply(
            message,
            'This user appears to be an administrator of this chat. I\'m sorry, but I cannot restrict administrators at this moment in time!'
        )
    end
    return mattata.send_message(
        message.chat.id,
        'Use the keyboard below to adjust what types of media <b>' .. mattata.escape_html(user.first_name) .. '</b> is allowed to send in <b>' .. mattata.escape_html(message.chat.title) .. '</b>:',
        'html',
        true,
        false,
        nil,
        restrict.get_keyboard(
            message.chat.id,
            user.id
        )
    )
end

return restrict