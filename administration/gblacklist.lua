--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local blacklist = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function blacklist:init(configuration)
    blacklist.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('gblacklist'):command('gwhitelist').table
end

function blacklist:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not mattata.is_global_admin(message.from.id) then
        return
    elseif not input then
        return
    end
    local arguments = message.text_lower:gsub('^' .. configuration.command_prefix .. 'blacklist ', ''):gsub('^' .. configuration.command_prefix .. 'whitelist ', '')
    if message.text_lower:match('^' .. configuration.command_prefix .. 'blacklist') then
        if tonumber(arguments) == nil then
            return mattata.send_reply(
                message,
                language.specify_blacklisted_user
            )
        end
        local hash = 'global_blacklist:' .. input
        redis:set(
            hash,
            true
        )
        return mattata.send_reply(
            message,
            language.user_now_blacklisted
        )
    end
    if tonumber(arguments) == nil then
        return mattata.send_reply(
            message,
            language.specify_blacklisted_user
        )
    end
    local hash = 'global_blacklist:' .. input
    redis:del(hash)
    return mattata.send_reply(
        message,
        language.user_now_whitelisted
    )
end

return blacklist