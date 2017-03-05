--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local nick = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function nick:init()
    nick.commands = mattata.commands(
        self.info.username
    ):command('nick').table
    nick.help = '/nick <nickname> - Sets your nickname. Pass "-del" as your nickname to remove it.'
end

function nick:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            nick.help
        )
    end
    if input == '-del' then
        redis:del('nick:' .. message.from.id)
        return mattata.send_reply(
            message,
            'Your nickname has now been forgotten!'
        )
    end
    redis:set(
        'nick:' .. message.from.id,
        input
    )
    return mattata.send_reply(
        message,
        string.format(
            'Your nickname has been set to "%s"!',
            input
        )
    )
end

return nick