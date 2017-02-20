--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local version = {}

local mattata = require('mattata')

function version:init()
    version.commands = mattata.commands(
        self.info.username
    ):command('version')
     :command('about').table
    version.help = [[/version - Returns information about this instance of mattata. Alias: /about.]]
end

function version:on_message(message)
    return mattata.send_message(
        message.chat.id,
        string.format(
            '@%s AKA %s `[%s]` is running mattata %s, created by [Matthew Hesketh](https://t.me/wrxck). The source code is available on [GitHub](https://github.com/wrxck/mattata).',
            mattata.escape_markdown(self.info.username:lower()),
            mattata.escape_markdown(self.info.name),
            self.info.id,
            self.version
        ),
        'markdown'
    )
end

return version