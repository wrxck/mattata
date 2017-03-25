--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local custom = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function custom:init()
    custom.commands = mattata.commands(
        self.info.username
    ):command('custom')
     :command('hashtag')
     :command('trigger').table
    custom.help = '/custom <new | del | list> [#trigger] [value] - Sets a custom response to a #hashtag trigger. Aliases: /hashtag, /trigger.'
end

function custom:on_message(message, configuration)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(
            message,
            configuration.errors.supergroup
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        return mattata.send_reply(
            message,
            configuration.errors.admin
        )
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            custom.help
        )
    elseif input:match('^new (#%a+) (.-)$') then
        local trigger, value = input:match('^new (#%a+) (.-)$')
        redis:hset(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger),
            tostring(value)
        )
        return mattata.send_reply(
            message,
            'Success! That message will now be sent every time somebody uses ' .. trigger .. '!'
        )
    elseif input:match('^del (#%a+)$') then
        local trigger = input:match('^del (#%a+)$')
        local success = redis:hdel(
            'administration:' .. message.chat.id .. ':custom',
            tostring(trigger)
        )
        if not success then
            return mattata.send_reply(
                message,
                'The trigger ' .. trigger .. ' does not exist!'
            )
        end
        return mattata.send_reply(
            message,
            'The trigger ' .. trigger .. ' has been deleted!'
        )
    elseif input == 'list' then
        local custom_commands = redis:hkeys('administration:' .. message.chat.id .. ':custom')
        if not next(custom_commands) then
            return mattata.send_reply(
                message,
                'You don\'t have any custom commands set!'
            )
        end
        local custom_commands_list = {}
        for k, v in ipairs(custom_commands) do
            table.insert(
                custom_commands_list,
                v
            )
        end
        return mattata.send_reply(
            message,
            'Custom commands for ' .. message.chat.title .. ':\n' .. table.concat(
                custom_commands_list,
                '\n'
            )
        )
    end
    return mattata.send_reply(
        message,
        'To create a new, custom command, use the following syntax:\n/custom new #trigger <value>. To list all current triggers, use /custom list. To delete a trigger, use /custom del #trigger.'
    )
end

return custom