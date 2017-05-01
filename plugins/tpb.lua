--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local tpb = {}
local mattata = require('mattata')

function tpb:init()
    tpb.commands = mattata.commands(self.info.username)
    :command('tpb')
    :command('thepiratebay').table
    tpb.help = '/tpb - Sends a list of working Pirate Bay proxies. Alias: /thepiratebay.'
end

function tpb:on_message(message, configuration, language)
    local str = io.popen('curl "https://proxybay.one/list.txt"'):read('*all')
    if not str
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            '<pre>%s</pre>',
            mattata.escape_html(str)
        ),
        'html'
    )
end

return tpb