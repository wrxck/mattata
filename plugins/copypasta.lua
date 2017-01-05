--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local copypasta = {}

local mattata = require('mattata')

function copypasta:init(configuration)
    copypasta.arguments = 'copypasta'
    copypasta.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('copypasta'):command('😂').table
    copypasta.help = configuration.command_prefix .. 'copypasta - Riddles the replied-to message with cancerous emoji. Alias: ' .. configuration.command_prefix .. '😂.'
end

function copypasta:on_message(message, configuration, language)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            copypasta.help
        )
    end
    if message.reply_to_message.text:len() > tonumber(configuration.maximum_copypasta_length) then
        local output = language.copypasta_length:gsub('MAXIMUM', configuration.maximum_copypasta_length)
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local success = mattata.send_message(
        message.chat.id,
        io.popen('python3 plugins/copypasta.py ' .. mattata.escape_bash(message.reply_to_message.text_upper):gsub('\n', ' '):gsub('\'', ''):gsub('%"', ''):gsub('%(', ' '):gsub('%)', ' ')):read('*all')
    )
    if not success then
        return mattata.send_reply(
            message,
            language.copypasta_must_contain
        )
    end
end

return copypasta