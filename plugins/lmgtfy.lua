--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local lmgtfy = {}

local mattata = require('mattata')
local url = require('socket.url')

function lmgtfy:init(configuration)
    lmgtfy.arguments = 'lmgtfy <query>'
    lmgtfy.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('lmgtfy').table
    lmgtfy.help = '/lmgtfy <query> - Sends a LMGTFY link for the given search query.'
end

function lmgtfy:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            lmgtfy.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<i>Let me Google that for you!</i>\n' .. '<a href="https://lmgtfy.com/?q=' .. url.escape(input) .. '">' .. mattata.escape_html(input) .. '</a>',
        'html'
    )
end

return lmgtfy