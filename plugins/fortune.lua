--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fortune = {}

local mattata = require('mattata')

function fortune:init()
    fortune.commands = mattata.commands(
        self.info.username
    ):command('fortune').table
    fortune.help = [[/fortune - Sends your fortune (featuring a seasonally-adjusting ASCII animal!).]]
end

function fortune:on_message(message)
    local command = 'cowsay '
    local month = os.date(
        '*t',
        os.time()
    ).month
    if month == 1 or month == 2 or month == 3 then -- Winter-themed
        command = command .. '-f moose '
    elseif month == 4 then -- Spring-themed
        command = command .. '-f sheep '
    elseif month == 10 then -- Halloween-themed
        command = command .. '-f skeleton '
    elseif month == 12 then -- Christmas-themed
        command = command .. '-f snowman '
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(
            io.popen(
                string.format(
                    '%s"$(fortune)" && echo "\nvia @%s"',
                    command,
                    self.info.username
                )
            ):read('*all')
        ) .. '</pre>',
        'html'
    )
end

return fortune