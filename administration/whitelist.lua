--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local whitelist = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function whitelist:init(configuration)
    whitelist.arguments = 'whitelist <user>'
    whitelist.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('whitelist'):command('unblacklist').table
    whitelist.help = configuration.command_prefix .. 'whitelist <user> - Whitelists the given user (or the replied-to user, if no username or ID is specified) to use ' .. self.info.first_name .. ' in the chat. Alias: ' .. configuration.command_prefix .. 'unblacklist.'
end

function whitelist:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return
    elseif not message.reply_to_message and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to whitelist, or specify them by username/ID.'
        )
    elseif message.reply_to_message then
        if mattata.is_group_admin(
            message.chat.id,
            message.reply_to_message.from.id
        ) then
            return mattata.send_reply(
                message,
                'I can\'t whitelist that user, they\'re an administrator in this chat.'
            )
        elseif message.reply_to_message.from.id == self.info.id then
            return
        end
        local user = message.reply_to_message.from.id
        local hash = 'group_whitelist:' .. message.chat.id .. ':' .. user
        redis:del(hash)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. message.reply_to_message.from.first_name .. ' [' .. message.reply_to_message.from.id .. '] to use ' .. self.info.username .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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
                'I can\'t whitelist that user, they\'re an administrator in this chat.'
            )
        elseif resolved.result.id == self.info.id then
            return
        end
        local user = resolved.result.id
        local hash = 'group_whitelist:' .. message.chat.id .. ':' .. user
        redis:del(hash)
        local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] to use ' .. self.info.first_name .. ' in ' .. message.chat.title .. ' [' .. message.chat.id .. '].'
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

return whitelist