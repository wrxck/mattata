--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local sed = {}

local mattata = require('mattata')
local json = require('dkjson')

function sed:init(configuration)
    sed.arguments = 's/<pattern>/<substitution>'
    sed.commands = {
        configuration.command_prefix .. '?s/.-/.-$'
    }
    sed.help = 's/<pattern>/<substitution> - Replaces all occurences of text matching a given Lua pattern with the given substitution.'
end

function sed:on_callback_query(callback_query, message, configuration)
    local message_title = message.text:match('^(.-):')
    message_title = '<b>' .. message_title .. ':</b>\n'
    local message_text = message.text:match(':\n(.-)$')
    local output = message_title .. message_text
    if callback_query.data:match('^yes$') then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output .. '\n\n<i>' .. mattata.escape_html(callback_query.from.first_name) .. ' is confident they didn\'t mean this!</i>',
            'html'
        )
    elseif callback_query.data:match('^no$') then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output .. '\n\n<i>WELP! ' .. mattata.escape_html(callback_query.from.first_name) .. ' admitted defeat...</i>',
            'html'
        )
    elseif callback_query.data:match('^maybe$') then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            output .. '\n\n<i>' .. mattata.escape_html(callback_query.from.first_name) .. ' isn\'t sure if they were mistaken or not.</i>',
            'html'
        )
    end
end

function sed:on_message(message)
    if not message.reply_to_message then
        return
    end
    local matches, substitution = message.text:match('^/?[sS]/(.-)/(.-)/?$')
    if not substitution then
        return
    elseif message.reply_to_message.from.id == self.info.id then
        return mattata.send_reply(
            message,
            'Screw you, I\'m always right.'
        )
    end
    substitution = substitution:gsub('\\n', '\n'):gsub('\\/', '/')
    local res, output = pcall(
        function()
            return message.reply_to_message.text:gsub(matches, substitution)
        end
    )
    if not res then
        return mattata.send_reply(
            message,
            'Invalid Lua pattern(s)!'
        )
    end
    output = mattata.trim(output)
    if output == message.reply_to_message.text then -- If the user has done something wrong, let them know they've done something wrong!
        return mattata.send_reply(
            message,
            'Are you stupid? There\'s no difference between the original text and the post-substitution text.'
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = '👍',
                ['callback_data'] = 'sed:yes'
            },
            {
                ['text'] = '😭',
                ['callback_data'] = 'sed:no'
            },
            {
                ['text'] = '🤔',
                ['callback_data'] = 'sed:maybe'
            }
        }
    }
    return mattata.send_message(
        message.chat.id,
        '<b>Hi, ' .. mattata.escape_html(message.reply_to_message.from.first_name) .. ', are you sure you didn\'t mean:</b>\n' .. mattata.escape_html(output),
        'html',
        true,
        false,
        message.reply_to_message.message_id,
        json.encode(keyboard)
    )
end

return sed