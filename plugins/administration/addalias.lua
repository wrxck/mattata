--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local addalias = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function addalias:init(configuration)
    addalias.commands = mattata.commands(self.info.username):command('addalias'):command('setalias').table
    addalias.help = '/addalias </alias> </command> - Allows custom aliases to be bound to existing commands. The alias must not be an existing command. All aliases/commands are automatically converted into lowercase text, and can contain letters, numbers and underscores. Alias: /setalias.'
    addalias.limits = configuration.administration.aliases
end

function addalias:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local input = mattata.input(message.text)
    if not input or not input:match('^/[%w_]+ /[%w_]+$') then
        return mattata.send_reply(message, 'Please use the format /addalias /command /alias.')
    end
    local existing, alias = input:match('^/([%w_]+) /([%w_]+)$')
    local length = alias:len()
    if length < addalias.limits.length.min then
        return mattata.send_reply(message, 'The alias must be a minimum of ' .. addalias.limits.length.min .. ' characters long!')
    elseif length > addalias.limits.length.max then
        return mattata.send_reply(message, 'The alias must not be longer than ' .. addalias.limits.length.max .. ' characters long!')
    end
    local total = redis:hgetall('chat:' .. message.chat.id .. ':aliases')
    if #total >= addalias.limits.total then
        return mattata.send_reply(message, 'You\'ve can\'t add anymore than ' .. addalias.limits.total .. ' aliases, please use /aliases and delete some to add more!')
    end
    existing = existing:lower()
    alias = alias:lower()
    local plugins = self.plugins
    local all = {}
    for _, plugin in pairs(plugins) do
        for _, command in pairs(plugin.commands) do
            table.insert(all, command)
        end
    end
    local is_valid = false
    for _, command in pairs(all) do
        if ('/' .. alias):match(command) then
            return mattata.send_reply(message, 'You can\'t set this as a command alias, because this is already bound to a plugin!')
        elseif ('/' .. existing):match(command) then
            is_valid = true
        end
    end
    if not is_valid then
        return mattata.send_reply(message, 'I couldn\'t set that as an alias because the command you specified doesn\'t exist!')
    end
    local exists = redis:hget('chat:' .. message.chat.id .. ':aliases', alias)
    if exists then
        return mattata.send_reply(message, 'I can\'t set /' .. alias .. ' as an alias because it\'s already bound to the following command: /' .. exists)
    end
    redis:hset('chat:' .. message.chat.id .. ':aliases', alias, existing)
    return mattata.send_reply(message, 'Success! You can now trigger the command /' .. existing .. ' using the alias /' .. alias .. '!')
end

return addalias