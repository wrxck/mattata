--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local afk = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function afk:init()
    afk.commands = mattata.commands(self.info.username):command('afk').table
    afk.help = '/afk [note] - Mark yourself as away from keyboard, with an optional note that will be displayed to users who mention you whilst you\'re away. You must have an @username for this feature to work.'
end

function afk:on_message(message, configuration, language)
    if not message.from.username
    then
        return mattata.send_reply(
            message,
            language['afk']['1']
        ) -- Since this feature relies on detecting username mentions, this feature
        -- is currently only available to users who have a public @username.
    elseif redis:hget(
        'afk:' .. message.chat.id .. ':' .. message.from.id,
        'since'
    ) -- Check if the user is already marked as AFK.
    then
        local since = redis:hget(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'since'
        )
        -- Un-mark the user as AFK in the database.
        redis:hdel(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'since'
        )
        redis:hdel(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'note'
        )
        return mattata.send_message(
            message.chat.id,
            string.format(
                language['afk']['2'],
                message.from.first_name,
                mattata.format_time(os.time() - tonumber(since))
            )
        ) -- Inform the chat of the user's return, and include the time they spent
        -- marked as AFK.
    end
    local input = mattata.input(message.text)
    and '\n' .. language['afk']['3'] .. ': ' .. mattata.input(message.text)
    or ''
    redis:hset(
        'afk:' .. message.chat.id .. ':' .. message.from.id,
        'since',
        os.time()
    )
    redis:hset(
        'afk:' .. message.chat.id .. ':' .. message.from.id,
        'note',
        input
    )
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['afk']['4'],
            message.from.first_name,
            input
        )
    )
end

return afk