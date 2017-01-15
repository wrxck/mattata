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
    ):command('lua'):command('return'):command('broadcast'):command('gbroadcast'):command('usercount'):command('groupcount').table
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
    if not input and message.text_lower ~= configuration.command_prefix .. 'usercount' and message.text_lower ~= configuration.command_prefix .. 'groupcount' then
        return mattata.send_reply(
            message,
            'Please enter a string of lua to execute'
        )
    end
    if message.text_lower:match('^' .. configuration.command_prefix .. 'groupcount$') then
        local group_count = 0
        for k, v in pairs(groups) do
            group_count = group_count + 1
        end
        return mattata.send_message(
            message.chat.id,
            group_count
        )
    elseif message.text:match('^' .. configuration.command_prefix .. 'gbroadcast') then
        local text = message.text:gsub('^' .. configuration.command_prefix .. 'gbroadcast ', '')
        for k, v in pairs(groups) do
            mattata.send_message(
                v.id,
                text,
                'markdown'
            )
        end
        return mattata.send_reply(
            message,
            'Done!'
        )
    else
        if message.text_lower:match('^' .. configuration.command_prefix .. 'return') then input = 'return ' .. input end
        local output, success = loadstring(
            [[
                local mattata = require('mattata')
                local json = require('dkjson')
                local url = require('socket.url')
                local utf8 = require('lua-utf8')
                local http = require('socket.http')
                local https = require('ssl.https')
                return function (message, configuration, self) ]] .. input .. [[ end
            ]]
        )
        if output == nil then
            output = success
        else
            success, output = xpcall(
                output(),
                lua.error_message,
                message,
                configuration
            )
        end
        if output ~= nil then
            if type(output) == 'table' then
                local str = lua.serialise(output)
                output = str
            end
            output = '```\n' .. tostring(output) .. '\n```'
        end
        return mattata.send_message(
            message.chat.id,
            output,
            'markdown'
        )
    end
end

return lua