--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local bash = {}
local mattata = require('mattata')

function bash:init()
    bash.commands = mattata.commands(self.info.username):command('bash').table
end

function bash.on_message(_, message, _, language)
    if not mattata.is_global_admin(message.from.id) then
        return false
    end
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, language['bash']['1'])
    end
    local res = io.popen(input)
    local output = res:read('*all')
    res:close()
    output = output:len() == 0 and language['bash']['2'] or string.format('<pre>%s</pre>', mattata.escape_html(output))
    return mattata.send_message(message.chat.id, output, 'html')
end

return bash