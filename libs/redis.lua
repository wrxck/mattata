--[[

                     _   _        _                           _ _
     _ __ ___   __ _| |_| |_ __ _| |_ __ _       _ __ ___  __| (_)___
    | '_ ` _ \ / _` | __| __/ _` | __/ _` |_____| '__/ _ \/ _` | / __|
    | | | | | | (_| | |_| || (_| | || (_| |_____| | |  __/ (_| | \__ \
    |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|     |_|  \___|\__,_|_|___/

    Copyright (c) 2017 Matthew Hesketh
    See LICENSE for details

    mattata-redis is a small Lua library to connect mattata to redis.
    Intended for use with the mattata library, a feature-packed Telegram bot.

]]--

local redis = require('redis')
local configuration = require('configuration')

redis.commands.hgetall = redis.command('hgetall', {
    ['response'] = function(response, command, ...)
        local request = {}
        for i = 1, #response, 2 do
            local n = response[i]
            request[n] = response[i + 1]
        end
        return request
    end
})

if not configuration.redis then
    print('The redis table could not be found in configuration.lua!')
    return false
elseif not configuration.redis.host then
    print('Please specify the host address of your redis database in the redis table of configuration.lua. Unless you have changed it, this will be 127.0.0.1.')
    return false
elseif not configuration.redis.port then
    print('Please specify the port of your redis database in the redis table of configuration.lua. Unless you have changed it, this will be 6379.')
    return false
elseif tonumber(configuration.redis.port) == nil then
    print('The value of port in the redis table of configuration.lua must be numerical!')
    return false
end

local success = pcall(function()
    local params = {
        ['host'] = configuration.redis.host,
        ['port'] = configuration.redis.port
    }
    redis = redis.connect(params)
end)

if not success then
    print('An error has occured whilst connecting to redis!')
    return false
end

if configuration.redis.db and configuration.redis.db ~= '' then
    if tonumber(configuration.redis.db) == nil then
        print('The value of db in the redis table of configuration.lua must be numerical!')
        return false
    end
    redis:select(
        tonumber(configuration.redis.db)
    )
end

if configuration.redis.password and configuration.redis.password ~= '' and type(configuration.redis.password) == 'string' then
    redis:auth(configuration.redis.password)
end

return redis