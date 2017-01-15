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
    copypasta.help = '/copypasta - Riddles the replied-to message with cancerous emoji. Alias: /😂.'
end

function copypasta.format_message(input)
    local emoji = { '😂', '😂', '😂', '😂', '👌', '✌', '💞', '👍', '👌', '💯', '🎶', '👀', '😂', '👓', '👏', '👐', '🍕', '💥', '🍴', '💦', '💦', '🍑', '🍆', '😩', '😏', '👉👌', '👀', '👅', '😩' }
    local output = {}
    for i = 1, input:len() do
        local c = input:sub(i, i)
        if c == ' ' then
            for _ = 1, math.random(3) do
                c = c .. emoji[math.random(#emoji)] .. c
            end
        end
        table.insert(
            output,
            c
        )
    end
    return table.concat(output)
end

function copypasta:on_message(message, configuration, language)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            copypasta.help
        )
    end
    if message.reply_to_message.text:len() > tonumber(configuration.max_copypasta_length) then
        local output = language.copypasta['45']:gsub('MAXIMUM', configuration.max_copypasta_length)
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    return mattata.send_message(
        message.chat.id,
        copypasta.format_message(message.reply_to_message.text_upper)
    )
end

return copypasta