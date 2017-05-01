--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local custom = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function custom:init()
    custom.commands = mattata.commands(self.info.username)
    :command('custom')
    :command('hashtag')
    :command('trigger').table
    custom.help = '/custom <new | del | list> [#trigger] [value] - Sets a custom response to a #hashtag trigger. Aliases: /hashtag, /trigger.'
end

function custom:on_message(message, configuration, language)
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
    end
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            custom.help
        )
    elseif input:match('^new (#%a+) (.-)$')
    then
        local trigger, value = input:match('^new (#%a+) (.-)$')
        redis:hset(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger),
            tostring(value)
        )
        return mattata.send_reply(
            message,
            string.format(
                language['custom']['1'],
                trigger
            )
        )
    elseif input:match('^del (#%a+)$')
    then
        local trigger = input:match('^del (#%a+)$')
        local success = redis:hdel(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger)
        )
        if not success
        then
            return mattata.send_reply(
                message,
                string.format(
                    language['custom']['2'],
                    trigger
                )
            )
        end
        return mattata.send_reply(
            message,
            string.format(
                language['custom']['3'],
                trigger
            )
        )
    elseif input == 'list'
    then
        local custom_commands = redis:hkeys('administration:' .. message.chat.id .. ':custom')
        if not next(custom_commands)
        then
            return mattata.send_reply(
                message,
                language['custom']['4']
            )
        end
        local custom_commands_list = {}
        for k, v in ipairs(custom_commands)
        do
            table.insert(
                custom_commands_list,
                v
            )
        end
        return mattata.send_reply(
            message,
            string.format(
                language['custom']['5'],
                message.chat.title
            ) .. table.concat(
                custom_commands_list,
                '\n'
            )
        )
    end
    return mattata.send_reply(
        message,
        language['custom']['6']
    )
end

return custom