--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local name = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function name:init(configuration)
    name.arguments = 'name'
    name.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('name').table
    name.help = '/name <text> - Change the name mattata responds to.'
end

function name.set_name(chat_id, input)
    redis:set(
        string.format(
            'chat:%s:name',
            chat_id
        ),
        input
    )
end

function name.get_name(chat_id)
    return redis:get(
        string.format(
            'chat:%s:name',
            chat_id
        )
    ) or 'mattata'
end

function name:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            string.format(
                'The name I currently respond to is "%s" - to change this, use /name <text> (where <text> is what you want me to respond to).',
                name.get_name(message.chat.id)
            )
        )
    end
    local is_admin = false
    if message.chat.type == 'private' then
        is_admin = true
    elseif mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) then
        is_admin = true
    end
    if is_admin == false then
        return mattata.send_reply(
            message,
            'I\'m sorry, but you need to be an administrator of this chat to be able to use this command!'
        )
    end
    if input:len() < 2 or input:len() > 32 then
        return mattata.send_reply(
            message,
            'My new name needs to be between 2 and 32 characters long!'
        )
    elseif input:gsub('%s', ''):match('%W') then
        return mattata.send_reply(
            message,
            'My name may only contain alphanumeric characters!'
        )
    end
    local old_name = name.get_name(message.chat.id)
    name.set_name(
        message.chat.id,
        input
    )
    return mattata.send_reply(
        message,
        string.format(
            'I will now respond to "%s", instead of "%s" - to change this, use /name <text> (where <text> is what you want me to respond to).',
            input,
            old_name
        )
    )
end

return name