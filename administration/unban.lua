--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local unban = {}

local mattata = require('mattata')

function unban:init(configuration)
    unban.arguments = 'unban <user>'
    unban.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('unban').table
    unban.help = configuration.command_prefix .. 'unban <user> - Unbans the given user (or the replied-to user, if no username or ID is specified) from the chat.'
end

function unban:on_message(message, configuration)
    local input = mattata.input(message.text)
    if message.chat.type ~= 'supergroup' or not mattata.is_group_admin(message.chat.id, message.from.id) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to unban, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(message.chat.id, message.reply_to_message.from.id) then
            return mattata.send_reply(
                message,
                'I can\'t unban that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == self.info.id then
            return
        end
        local success = mattata.unban_chat_member(message.chat.id, message.reply_to_message.from.id)
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t unban ' .. message.reply_to_message.from.first_name .. ' because I\'m not an administrator in this chat.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
        if input then output = output .. '\nReason: ' .. input end
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
                'I can\'t unban that user, they\'re an administrator in this chat and was never banned in the first place.'
            )
        elseif resolved.result.id == self.info.id then
            return
        end
        local success = mattata.unban_chat_member(
            message.chat.id,
            resolved.result.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t unban ' .. resolved.result.first_name .. ' because they\'re either not a member of this chat, or I\'m not an administrator.'
            )
        end
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has unbanned ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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

return unban