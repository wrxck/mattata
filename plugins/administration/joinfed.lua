--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local joinfed = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function joinfed:init(configuration)
    joinfed.commands = mattata.commands(self.info.username):command('joinfed').table
    joinfed.help = '/joinfed <fed UUID> - Allows a group admin to join the current group to the specified Fed.'
    joinfed.limit = configuration.administration.feds.group_limit
    joinfed.groups = configuration.administration.feds.shortened_feds
end

function joinfed:on_message(message, configuration, language)
    if message.chat.type == 'private' then
        return mattata.send_reply(message, 'Please use this command in the group you would like to join to the Fed!')
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, 'Please specify the fed\'s UUID!')
    end
    for name, fed in pairs(joinfed.groups) do
        if input:lower() == name then
            input = fed
        end
    end
    if not input:match('^%w+%-%w+%-%w+%-%w+%-%w+$') then
        return mattata.send_reply(message, 'That\'s an invalid UUID format')
    end
    local feds = redis:smembers('chat:' .. message.chat.id .. ':feds')
    if redis:sismember('chat:' .. message.chat.id .. ':feds', input) then
        return mattata.send_reply(message, 'This group is already part of that Fed!')
    elseif #feds >= joinfed.limit then
        return mattata.send_reply(message, 'You can only join a maximum of ' .. joinfed.limit .. ' Feds per group!')
    end
    local fed_title = redis:hget('fed:' .. input, 'title')
    if not fed_title then
        return mattata.send_reply(message, 'The Fed you specified doesn\'t exist!')
    end
    local output = 'Joined the Fed <b>%s</b> in this group <code>[%s]</code>!'
    redis:sadd('chat:' .. message.chat.id .. ':feds', input)
    redis:sadd('fedmembers:' .. input, message.chat.id)
    fed_title = mattata.escape_html(fed_title)
    output = string.format(output, fed_title, message.chat.id)
    return mattata.send_reply(message, output, 'html')
end

return joinfed