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
    local developer = mattata.get_formatted_user(221714512, 'Matt', 'html')
    local output = 'Created by %s. Powered by <code>mattata v%s</code> and %s. Latest stable source code available <a href="https://github.com/wrxck/mattata">on GitHub</a>.'
    return mattata.send_message(message.chat.id, string.format(output, developer, self.version, utf8.char(10084)), 'html')
end

return about