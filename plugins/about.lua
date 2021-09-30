--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local about = {}
local mattata = require('mattata')

function about:init()
    about.commands = mattata.commands(self.info.username):command('about').table
    about.help = '/about - View information about the bot.'
end

function about:on_message(message)
    local author = mattata.get_formatted_user(221714512, 'Matt', 'html')
    local maintainer = mattata.get_formatted_user(103053641, 'Italo', 'html')
    local output = table.concat({
        string.format('Created by %s.', author),
        string.format('Maintained by %s.', maintainer),
        string.format('Powered by <code>mattata v%s</code> and %s.', self.version, utf8.char(10084)),
        string.format('Latest stable source code available <a href="%s">on GitHub</a>.', 'https://github.com/italomaia/mattata'),
    }, ' ')
    return mattata.send_message(message.chat.id, output, 'html')
end

return about