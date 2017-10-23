--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local gwhitelist = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function gwhitelist:init()
    gwhitelist.commands = mattata.commands(self.info.username):command('gwhitelist').table
end

function gwhitelist:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not mattata.is_global_admin(message.from.id)
    then
        return
    elseif not message.reply
    and not input
    then
        return mattata.send_reply(
            message,
            language['gwhitelist']['1']
        )
    elseif message.reply
    then
        input = message.reply.from.id
    end
    if tonumber(input) == nil
    and not input:match('^@')
    then
        input = '@' .. input
    end
    local resolved = mattata.get_user(input)
    or mattata.get_chat(input)
    if not resolved
    then
        return mattata.send_reply(
            message,
            string.format(
                language['gwhitelist']['2'],
                input
            )
        )
    elseif resolved.result.type ~= 'private'
    then
        return mattata.send_reply(
            message,
            string.format(
                language['gwhitelist']['3'],
                resolved.result.type
            )
        )
    end
    if resolved.result.id == self.info.id
    or mattata.is_global_admin(resolved.result.id)
    then
        return
    end
    local user = resolved.result.id
    local hash = 'global_blacklist:' .. user
    redis:del(hash)
    local output = message.from.first_name .. ' [' .. message.from.id .. '] has whitelisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] to use ' .. self.info.first_name .. '.'
    if configuration.log_admin_actions
    and configuration.log_channel ~= ''
    then
        mattata.send_message(
            configuration.log_channel,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(output) .. '</pre>',
        'html'
    )
end

return gwhitelist