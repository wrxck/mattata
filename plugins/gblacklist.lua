--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local gblacklist = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function gblacklist:init()
    gblacklist.commands = mattata.commands(
        self.info.username
    ):command('gblacklist').table
end

function gblacklist:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not mattata.is_global_admin(message.from.id) then
        return
    elseif not message.reply and not input then
        return mattata.send_reply(
            message,
            'Please reply-to the user you\'d like to blacklist, or specify them by username/ID.'
        )
    elseif message.reply then
        input = message.reply.from.id
    end
    if tonumber(input) == nil and not input:match('^@') then
        input = '@' .. input
    end
    local resolved = mattata.get_user(input) or mattata.get_chat(input)
    if not resolved then
        return mattata.send_reply(
            message,
            'I couldn\'t get information about \'' .. input .. '\', please check it\'s a valid username/ID and try again.'
        )
    elseif resolved.result.type ~= 'private' then
        return mattata.send_reply(
            message,
            'That\'s a ' .. resolved.result.type .. ', not a user!'
        )
    end
    if resolved.result.id == self.info.id or mattata.is_global_admin(resolved.result.id) then
        return
    end
    local user = resolved.result.id
    local hash = 'global_blacklist:' .. user
    redis:set(
        hash,
        true
    )
    local output = message.from.first_name .. ' [' .. message.from.id .. '] has blacklisted ' .. resolved.result.first_name .. ' [' .. resolved.result.id .. '] from using ' .. self.info.first_name .. '.'
    if configuration.log_admin_actions and configuration.log_channel ~= '' then
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

return gblacklist