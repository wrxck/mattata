--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local lua = {}

local mattata = require('mattata')
local url = require('socket.url')
local utf8 = require('lua-utf8')
local json = require('serpent')
local users, groups

function lua:init(configuration)
    lua.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('lua').table
    json = require('dkjson')
    lua.serialise = function(input)
        return json.encode(
            input,
            {
                indent = true
            }
        )
    end
    lua.loadstring = load or loadstring
    lua.error_message = function(x)
        return 'Error:\n' .. tostring(x)
    end
    groups = self.groups
end

function lua:on_message(message, configuration)
    if not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please enter a string of Lua to execute!'
        )
    end
    local output, success = loadstring(
        [[
            local mattata = require('mattata')
            local https = require('ssl.https')
            local http = require('socket.http')
            local url = require('socket.url')
            local ltn12 = require('ltn12')
            local json = require('dkjson')
            local utf8 = require('lua-utf8')
            local redis = require('mattata-redis')
            local socket = require('socket')
            return function (message, configuration, self)
        ]] .. input .. ' end'
    )
    if success == nil then
        success, output = xpcall(
            output(),
            lua.error_message,
            message,
            configuration
        )
    end
    if output ~= nil and type(output) == 'table' then
        output = lua.serialise(output)
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(tostring(output)) .. '</pre>',
        'html'
    )
end

return lua