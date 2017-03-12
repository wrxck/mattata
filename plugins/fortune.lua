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

function fortune.get_animals()
    local animals = {}
    for n in string.gmatch(
        io.popen('cowsay -l'):read('*all'):match(':(.+)$'),
        '[%S]+'
    ) do
        table.insert(
            animals,
            n
        )
    end
    return animals
end

function fortune:on_message(message)
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(
            io.popen(
                string.format(
                    '%s -f %s "$(fortune)" && echo "\nvia @%s"',
                    math.random(2) == 1 and 'cowsay' or 'cowthink',
                    fortune.get_animals()[math.random(#fortune.get_animals())],
                    self.info.username
                )
            ):read('*all')
        ) .. '</pre>',
        'html'
    )
end

return fortune