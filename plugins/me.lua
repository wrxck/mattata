--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local me = {}

local mattata = require('mattata')

function me:init(configuration)
    me.arguments = 'me'
    me.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('me').table
    me.help = '/me <emote message> - Allows you to emote.'
end

function me:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            me.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<code>* %s %s</code>',
            mattata.escape_html(message.from.name),
            mattata.escape_html(input)
        ),
        'html'
    )
end

return me