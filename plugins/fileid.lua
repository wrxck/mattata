--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fileid = {}
local mattata = require('mattata')

function fileid:init()
    fileid.commands = mattata.commands(
        self.info.username
    ):command('fileid').table
    fileid.help = '/fileid - Returns the ID of the replied-to file.'
end

function fileid:on_message(message, configuration)
    if not message.reply
    or (
        message.reply
        and not message.reply.file_id
    )
    then
        return mattata.send_reply(
            message,
            fileid.help
        )
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(message.reply.file_id) .. '</pre>',
        'html'
    )
end

return fileid