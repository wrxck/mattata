--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local link = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function link:init(configuration)
    link.arguments = 'link'
    link.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('link'):command('setlink').table
    link.help = configuration.command_prefix .. 'link - Get the group link. Alias: ' .. configuration.command_prefix .. 'setlink.'
end

function link.set_link(message, link)
    local hash = mattata.get_redis_hash(
        message,
        'link'
    )
    if hash then
        redis:hset(
            hash,
            'link',
            link
        )
        return 'Successfully set the new link.'
    end
end

function link.get_link(message)
    local hash = mattata.get_redis_hash(
        message,
        'link'
    )
    if hash then
        local link = redis:hget(
            hash,
            'link'
        )
        if not link or link == 'false' then
            return 'There isn\'t a link set for this group.'
        end
        return link
    end
end

function link:on_message(message, configuration)
    if not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) or not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    local output
    if not input then
        output = link.get_link(message)
        if not output then
            output = 'There isn\'t a link set for this group.'
            if mattata.is_group_admin(
                message.chat.id,
                message.from.id
            ) then
                output = output ..  '\nYou can set one with \'' .. configuration.command_prefix .. 'link <value>\'.'
            end
        else
            output = '<a href="' .. output .. '">' .. mattata.escape_html(message.chat.title) .. '</a>'
        end
    else
        if message.entities[2] and message.entities[2].type == 'url' and message.entities[2].offset == message.entities[1].offset + message.entities[1].length + 1 and message.entities[2].length == input:len() then -- Checks to ensure that only a URL was sent as an argument.
            output = link.set_link(message, input)
        else
            output = 'That\'s not a valid url.'
        end
    end
    local success = mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
    if not success then
        return mattata.send_reply(
            message,
            'There was an error sending the group link, it\'s probably not valid.'
        )
    end
end

return link