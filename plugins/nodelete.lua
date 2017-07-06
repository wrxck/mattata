--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local nodelete = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function nodelete:init()
    nodelete.commands = mattata.commands(self.info.username):command('nodelete').table
    nodelete.help = '/nodelete [add | del] <plugins> - Allows the given plugins to retain the commands they were executed with by whitelisting them from the "delete commands" administrative setting. Multiple plugins can be specified.'
end

function nodelete:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if message.chat.type ~= 'supergroup'
    then
        return mattata.send_reply(
            message,
            language['errors']['supergroup']
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    )
    then
        return mattata.send_reply(
            message,
            language['errors']['admin']
        )
    elseif not input
    or not input:match('^add .-$')
    and not input:match('^del .-$')
    then
        return mattata.send_reply(
            message,
            nodelete.help
        )
    end
    local plugins = {}
    local process_type, input = input:match('([ad][de][dl]) (.-)$')
    for plugin in input:gmatch('[%w_]+')
    do
        for k, v in pairs(configuration.plugins)
        do
            if v:lower() == plugin:lower()
            then
                table.insert(
                    plugins,
                    plugin
                )
            end
        end
    end
    if #plugins < 1
    then
        return mattata.send_reply(
            message,
            'No matching plugins were found!'
        )
    end
    local total = #plugins
    local success = {}
    for k, v in pairs(plugins)
    do
        if process_type == 'add'
        and not redis:sismember(
            'chat:' .. message.chat.id .. ':no_delete',
            v
        ) -- Check to make sure the plugin isn't already whitelisted from having
        -- its commands deleted.
        then
            redis:sadd(
                'chat:' .. message.chat.id .. ':no_delete',
                v
            )
            table.insert(
                success,
                v
            )
        elseif process_type == 'del'
        and redis:sismember(
            'chat:' .. message.chat.id .. ':no_delete',
            v
        ) -- Check to make sure the plugin has already been whitelisted from having
        -- its commands deleted.
        then
            redis:srem(
                'chat:' .. message.chat.id .. ':no_delete',
                v
            )
            table.insert(
                success,
                v
            )
        end
    end
    local output = process_type == 'del'
    and 'Commands will now be deleted for ' .. total .. ' plugins!'
    or 'Commands will no longer be deleted for ' .. total .. ' plugins!'
    return mattata.send_reply(
        message,
        output
    )
end

return nodelete