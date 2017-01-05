--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local jsondump = {}

local mattata = require('mattata')
local json = require('serpent')

function jsondump:init(configuration)
    jsondump.arguments = 'jsondump'
    jsondump.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('jsondump').table
    jsondump.help = configuration.command_prefix .. 'jsondump - Returns the raw json of your message.'
    json = require('dkjson')
    jsondump.serialise = function(input)
        return json.encode(
            input,
            {
                indent = true
            }
        )
    end
end

function jsondump:on_message(message)
    local output = jsondump.serialise(message)
    if output:len() > 4096 then
        return
    end
    return mattata.send_message(
        message.chat.id,
        '<pre>' .. mattata.escape_html(tostring(output)) .. '</pre>',
        'html'
    )
end

return jsondump