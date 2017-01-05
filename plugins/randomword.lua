--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local randomword = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function randomword:init(configuration)
    randomword.arguments = 'randomword'
    randomword.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('randomword'):command('rw').table
    randomword.help = configuration.command_prefix .. 'randomword - Generates a random word. Alias: ' .. configuration.command_prefix .. 'rw.'
end

function randomword.get_keyboard()
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Generate Another',
                ['callback_data'] = 'randomword:new'
            }
        }
    }
    return keyboard
end

function randomword:on_callback_query(callback_query, message, configuration, language)
    local str, res = http.request('http://www.setgetgo.com/randomword/get.php')
    if res ~= 200 then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            language.errors.connection
        )
    end
    local keyboard = randomword.get_keyboard()
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        'Your random word is <b>' .. str:lower() .. '</b>!',
        'html',
        true,
        json.encode(keyboard)
    )
end

function randomword:on_message(message, configuration, language)
    local str, res = http.request('http://www.setgetgo.com/randomword/get.php')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local keyboard = randomword.get_keyboard()
    return mattata.send_message(
        message.chat.id,
        'Your random word is <b>' .. str:lower() .. '</b>!',
        'html',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return randomword