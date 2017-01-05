--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local nick = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function nick:init(configuration)
    nick.arguments = 'nick <nickname>'
    nick.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('nick').table
    nick.help = configuration.command_prefix .. 'nick <nickname> - Set your nickname to the given value. If no value is given, your current nickname is sent instead.'
end

function nick.set_nick(user, nickname)
    local hash = mattata.get_user_redis_hash(
        user,
        'nickname'
    )
    if hash then
        redis:hset(
            hash,
            'nickname',
            nickname
        )
        return user.first_name .. '\'s nickname has been set to \'' .. nickname .. '\'.'
    end
end

function nick.del_nick(user)
    local hash = mattata.get_user_redis_hash(
        user,
        'nickname'
    )
    if redis:hexists(
        hash,
        'nickname'
    ) == true then
        redis:hdel(
            hash,
            'nickname'
        )
        return 'Your nickname has successfully been deleted.'
    else
        return 'You don\'t currently have a nickname!'
    end
end

function nick.get_nick(user)
    local hash = mattata.get_user_redis_hash(
        user,
        'nickname'
    )
    if hash then
        local nickname = redis:hget(
            hash,
            'nickname'
        )
        if not nickname or nickname == 'false' then
            return 'You don\'t have a nickname set.'
        else
            return 'Your nickname is currently \'' .. nickname .. '\'.'
        end
    end
end

function nick:on_message(message, configuration)
    local input = mattata.input(message.text)
    local output
    if not input then
        return mattata.send_reply(
            message,
            nick.get_nick(message.from)
        )
    end
    if message.text_lower == configuration.command_prefix .. 'nick -del' then
        return mattata.send_reply(
            message,
            nick.del_nick(message.from)
        )
    end
    return mattata.send_reply(
        message,
        nick.set_nick(message.from, input)
    )
end

return nick