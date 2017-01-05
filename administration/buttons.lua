--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local buttons = {}

local mattata = require('mattata')
local json = require('dkjson')

function buttons:init(configuration)
    buttons.arguments = 'buttons <text> \\n "text" = "url" \\n "text" = "url"'
    buttons.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('buttons').table
    buttons.help = configuration.command_prefix .. 'buttons <text>\n"text" = "url"\n"text" = "url"\n(and so forth...)'
end

function buttons.generate_keyboard(input)
    if not input:match('\n%".-%" %= %".-%"') then
        return false, false
    end
    local keyboard = {}
    keyboard.inline_keyboard = {}
    for text, url in input:gmatch('\n"(.-)" = "(.-)"') do
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = text,
                    ['url'] = url
                }
            }
        )
    end
    return input:gsub('\n%".-%" %= %".-%"', ''), keyboard
end

function buttons:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            buttons.help
        )
    end
    local output, keyboard = buttons.generate_keyboard(input)
    if not output then
        return mattata.send_reply(
            message,
            buttons.help
        )
    end
    local success = mattata.send_message(
        message.chat.id,
        output,
        nil,
        true,
        false,
        nil,
        json.encode(keyboard)
    )
    if not success then
        return mattata.send_reply(
            message,
            'There was an error processing your request, please check the button data is in the correct format and try again.'
        )
    end
end

return buttons