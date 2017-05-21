--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setlink = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function setlink:init()
    setlink.commands = mattata.commands(self.info.username):command('setlink').table
    setlink.help = '/setlink <link> - Sets the group\'s link.'
end

function setlink:on_message(message, configuration, language)
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
    if not input
    then
        return mattata.send_reply(
            message,
            setlink.help
        )
    end
    local output
    if message.entities[2]
    and message.entities[2].type == 'url'
    and message.entities[2].offset == message.entities[1].offset + message.entities[1].length + 1
    and message.entities[2].length == input:len()
    then -- Check to ensure that only a URL was sent as an argument.
        redis:hset(
            'chat:' .. message.chat.id .. ':values',
            'link',
            input
        )
        output = '<a href="' .. input .. '">' .. mattata.escape_html(message.chat.title) .. '</a>'
    end
    local success = mattata.send_message(
        message,
        output,
        'html'
    )
    if not success
    then
        return mattata.send_reply(
            message,
            language['setlink']['1']
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        success.result.message_id,
        language['setlink']['2']
    )
end

return setlink