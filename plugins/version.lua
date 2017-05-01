--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local version = {}
local mattata = require('mattata')

function version:init()
    version.commands = mattata.commands(self.info.username)
    :command('version')
    :command('about').table
    version.help = '/version - Returns information about this instance of mattata. Alias: /about.'
end

function version:on_message(message, configuration, language)
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['version']['1'],
            mattata.escape_markdown(
                self.info.username:lower()
            ),
            mattata.escape_markdown(self.info.name),
            self.info.id,
            self.version
        ),
        'markdown'
    )
end

return version