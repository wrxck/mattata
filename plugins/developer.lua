--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local developer = {}

local mattata = require('mattata')

function developer:init()
    developer.commands = mattata.commands(
        self.info.username
    ):command('developer')
     :command('dev').table
    developer.help = [[/developer - Connect with the developer through his social media. Alias: /dev.]]
end

function developer:on_message(message)
    return mattata.forward_message(
        message.chat.id,
        '@wrxck',
        false,
        33
    )
end

return developer