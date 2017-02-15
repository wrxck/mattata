--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local bash = {}

local mattata = require('mattata')

function bash:init()
    bash.commands = mattata.commands(
        self.info.username
    ):command('bash').table
end

function bash:on_message(message)
    if not mattata.is_global_admin(message.from.id) then
        return
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            'Please specify a command to run!'
        )
    end
    local output = io.popen(input):read('*all')
    io.popen(input):close()
    if output:len() == 0 then
        output = 'Success!'
    else
        output = '<pre>' .. mattata.escape_html(output) .. '</pre>'
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return bash