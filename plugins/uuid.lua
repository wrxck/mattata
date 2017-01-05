--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local uuid = {}

local mattata = require('mattata')
local socket = require('socket')
local uuidgen = require('uuid')

function uuid:init(configuration)
    uuid.arguments = 'uuid'
    uuid.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('uuid'):command('guid').table
    uuid.help = configuration.command_prefix .. 'uuid - Generates a random UUID.'
end

function uuid:on_message(message)
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. uuidgen() .. '</pre>',
        'html'
    )
end

return uuid