--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ahelp = {}

local mattata = require('mattata')

function ahelp:init()
    ahelp.commands = mattata.commands(
        self.info.username
    ):command('ahelp').table
    ahelp.help = '/ahelp - View administrative help.'
end

function ahelp:on_message(message, configuration)
    local help_message = [[
```
Administration Commands:

• /ban [user]
• /kick [user]
• /unban [user]
• /warn [user]
• /user [user]
• /links <text>
• /setrules <rules>
• /rules
• /link
• /setlink <link>
• /setwelcome <text>
• /mod [user]
• /demod [user]
• /pin <text>
• /report
• /staff

Arguments: [optional] <required>
```
    ]]
    return mattata.send_message(
        message.chat.id,
        help_message,
        'markdown',
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                'More Help',
                'help:ahelp:1'
            )
        )
    )
end

return ahelp