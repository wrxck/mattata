--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local share = {}
local mattata = require('mattata')
local url = require('socket.url')

function share:init()
    share.commands = mattata.commands(self.info.username):command('share').table
    share.help = '/share <url> <text> - Share the given URL through an inline button, with the specified text as the caption.'
end

function share:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    or not input:match('^.- .-$')
    then
        return mattata.send_reply(
            message,
            share.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        input:match('^.- (.-)$'),
        nil,
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():url_button(
                language['share']['1'] .. ' ' .. utf8.char(8618),
                'https://t.me/share/url?url=' .. url.escape(
                    input:match('^(.-) .-$')
                ) .. '&text=' .. url.escape(
                    input:match('^.- (.-)$')
                )
            )
        )
    )
end

return share