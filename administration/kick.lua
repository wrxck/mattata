--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local kick = {}

local mattata = require('mattata')

function kick:init(configuration)
    kick.arguments = 'kick <user>'
    kick.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('kick').table
    kick.help = configuration.command_prefix .. 'kick <user> - Kicks the given user (or the replied-to user, if no username or ID is specified) from the chat.'
end

function kick:on_message(message, configuration)
    local input = mattata.input(message.text)
    if message.chat.type ~= 'supergroup' or not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to kick, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(
            message.chat.id,
            message.reply_to_message.from.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t kick that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == self.info.id then
            return
        end
        local user = message.reply_to_message.from.id
        local kick = mattata.kick_chat_member(
            message.chat.id,
            user
        )
        if not kick then
            return mattata.send_reply(message, 'I couldn\'t kick ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.')
        end
        mattata.unban_chat_member(
            message.chat.id,
            user
        )
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has kicked ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then
            output = output .. '\nReason: ' .. input
        end
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    else
        if tonumber(input) == nil and not input:match('^@') then
            input = '@' .. input
        end
        local resolved = mattata.get_chat_pwr(input)
        if not resolved then
            return mattata.send_reply(
                message,
                'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
            )
        elseif resolved.result.type ~= 'private' then
            return mattata.send_reply(
                message,
                'That\'s a ' .. resolved.result.type .. ', not a user!'
            )
        end
        if mattata.is_group_admin(
            message.chat.id,
            resolved.result.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t kick that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == self.info.id then
            return
        end
        local user = resolved.result.id
        local kick = mattata.kick_chat_member(
            message.chat.id,
            user
        )
        if not kick then
            return mattata.send_reply(
                message,
                'I couldn\'t kick ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        end
        mattata.unban_chat_member(
            message.chat.id,
            user
        )
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has kicked ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if configuration.log_admin_actions and configuration.log_channel ~= '' then
            mattata.send_message(
                configuration.log_channel,
                '<pre>' .. mattata.escape_html(output) .. '</pre>',
                'html'
            )
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
end

return kick