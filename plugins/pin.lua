--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local pin = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function pin:init()
    pin.commands = mattata.commands(self.info.username):command('pin').table
    pin.help = '/pin <text> - Repeats the given string of text.'
end

function pin:on_message(message, configuration, language)
    if not mattata.is_group_admin(
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
    local last_pin = redis:get(
        string.format(
            'administration:%s:pin',
            message.chat.id
        )
    )
    local pin_exists = true
    if not input
    then
        if not last_pin
        then
            return mattata.send_reply(
                message,
                language['pin']['1']
            )
        end
        local success = mattata.send_message(
            message,
            language['pin']['2'],
            nil,
            true,
            false,
            last_pin
        )
        if not success
        then
            pin_exists = false
            return mattata.send_reply(
                message,
                language['pin']['3']
            )
        end
        return
    end
    local success = mattata.edit_message_text(
        message.chat.id,
        last_pin,
        input,
        'markdown'
    )
    if not success
    then
        mattata.send_reply(
            message,
            language['pin']['4']
        )
        local new_pin = mattata.send_message(
            message,
            input,
            'markdown',
            true,
            false
        )
        if not new_pin
        then
            return mattata.send_reply(
                message,
                language['pin']['5']
            )
        end
        redis:set(
            string.format(
                'administration:%s:pin',
                message.chat.id
            ),
            new_pin.result.message_id
        )
        last_pin = new_pin.result.message_id
    end
    return mattata.send_message(
        message,
        language['pin']['6'],
        nil,
        true,
        false,
        last_pin
    )
end

return pin