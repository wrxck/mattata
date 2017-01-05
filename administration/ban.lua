--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local ban = {}

local mattata = require('mattata')

function ban:init(configuration)
    ban.arguments = 'ban <user>'
    ban.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('ban').table
    ban.help = configuration.command_prefix .. 'ban <user> - Bans the given user (or the replied-to user, if no username or ID is specified) from the chat.'
end

function ban:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator of this chat to use this command.'
        )
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to ban, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                'I can\'t ban that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == self.info.id then
            return
        end
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has banned ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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
                input .. ' is a ' .. resolved.result.type .. ', not a user!'
            )
        elseif mattata.is_group_admin(message.chat.id, resolved.result.id) then
            return mattata.send_reply(
                message,
                'I can\'t ban that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == self.info.id then
            return
        end
        local success = mattata.kick_chat_member(
            message.chat.id,
            resolved.result.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has banned ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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

return ban