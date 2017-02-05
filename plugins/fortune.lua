--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local fortune = {}

local mattata = require('mattata')

function fortune:init(configuration)
    fortune.arguments = 'fortune'
    fortune.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('fortune').table
    fortune.help = '/fortune - Send your fortune.'
end

function fortune:on_message(message)
    local command = 'cowsay '
    local month = os.date('*t', os.time()).month
    if month == 1 or month == 2 or month == 3 then -- Winter theme
        command = command .. '-f moose '
    elseif month == 4 then -- Spring theme
        command = command .. '-f sheep '
    elseif month == 10 then -- Halloween theme
        command = command .. '-f skeleton '
    elseif month == 12 then -- Christmas theme
        command = command .. '-f snowman '
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(io.popen(command .. '"$(fortune)" && echo "\nvia @' .. self.info.username .. '"'):read('*all')) .. '</pre>',
        'html'
    )
end

return fortune