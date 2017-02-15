--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ping = {}

local mattata = require('mattata')

function ping:init()
    ping.commands = mattata.commands(
        self.info.username
    ):command('ping').table
end

function ping:on_message(message)
    return mattata.send_message(
        message.chat.id,
        'PONG'
    )
end

return ping