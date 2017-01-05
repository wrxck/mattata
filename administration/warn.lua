--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local warn = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')

function warn:init(configuration)
    warn.arguments = 'warn'
    warn.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('warn').table
    warn.help = configuration.command_prefix .. 'warn - Warn the replied-to user.'
end

function warn:on_callback_query(callback_query, message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        callback_query.from.id
    ) then
        return
    elseif callback_query.data:match('^reset:(.-)$') then
        redis:hdel(
            'chat:' .. message.chat.id .. ':warnings',
            callback_query.data:match('^reset:(.-)$')
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Warnings reset by ' .. callback_query.from.first_name
        )
    elseif callback_query.data:match('^remove:(.-)$') then
        local amount = redis:hincrby(
            'chat:' .. message.chat.id .. ':warnings',
            callback_query.data:match('^remove:(.-)$'),
            -1
        )
        local text, maximum, difference
        if tonumber(amount) < 0 then
            text = 'The number of warnings received by this user is already zero!'
            redis:hincrby(
                'chat:' .. message.chat.id .. ':warnings',
                callback_query.data:match('^remove:(.-)$'),
                1
            )
        else
            maximum = 3
            difference = tonumber(maximum) - tonumber(amount)
            text = string.format(
                'Warning removed! (%d/%d)',
                tonumber(amount),
                tonumber(maximum)
            )
        end
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            text
        )
    end
end

function warn:on_message(message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            'You must be an administrator to use this command!'
        )
    elseif not message.reply_to_message then
        return mattata.send_reply(
            message,
            'You must use this command via reply to the targeted user\'s message.'
        )
    elseif mattata.is_group_admin(
        message.chat.id,
        message.reply_to_message.from.id
    ) then
        return mattata.send_reply(
            message,
            'The targeted user is an administrator in this chat.'
        )
    end
    local name = message.reply_to_message.from.first_name
    local hash = 'chat:' .. message.chat.id .. ':warnings'
    local amount = redis:hincrby(
        hash,
        message.reply_to_message.from.id,
        1
    )
    local maximum = 3
    local text, res
    amount, maximum = tonumber(amount), tonumber(maximum)
    if amount >= maximum then
        text = message.reply_to_message.from.first_name .. ' was banned for reaching the maximum number of allowed warnings (' .. maximum .. ').'
        local success = mattata.kick_chat_member(
            message.chat.id,
            message.reply_to_message.from.id
        )
        if not success then
            return mattata.send_reply(
                message,
                'I couldn\'t ban that user. Please ensure that I\'m an administrator and that the targeted user isn\'t.'
            )
        end
        redis:hdel(
            'chat:' .. message.chat.id .. ':warnings',
            message.reply_to_message.from.id
        )
        return mattata.send_message(
            message.chat.id,
            text
        )
    end
    local difference = maximum - amount
    text = '*%s* has been warned `[`%d/%d`]`'
    if message.text_lower ~= configuration.command_prefix .. 'warn' then
        text = text .. '\n*Reason:* ' .. mattata.escape_markdown(message.text_lower:gsub('^' .. configuration.command_prefix .. 'warn ', ''))
    end
    text = text:format(
        mattata.escape_markdown(name),
        amount,
        maximum
    )
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Remove Warning',
                ['callback_data'] = 'warn:remove:' .. message.reply_to_message.from.id
            },
            {
                ['text'] = 'Reset Warnings',
                ['callback_data'] = 'warn:reset:' .. message.reply_to_message.from.id
            }
        }
    }
    return mattata.send_message(
        message.chat.id,
        text,
        'markdown',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return warn