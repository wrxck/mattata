--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local catfact = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function catfact:init(configuration)
    catfact.arguments = 'catfact'
    catfact.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('catfact').table
    catfact.help = configuration.command_prefix .. 'catfact - A random cat-related fact!'
end

function catfact:on_inline_query(inline_query)
    local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = jdat.facts[1]:gsub('â', ' '),
                    ['description'] = 'Click to send the result.',
                    ['input_message_content'] = {
                        ['message_text'] = jdat.facts[1]:gsub('â', ' ')
                    }
                }
            }
        )
    )
end

function catfact:on_message(message, configuration, language)
    local jstr, res = http.request('http://catfacts-api.appspot.com/api/facts')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        jdat.facts[1]:gsub('â', ' ')
    )
end

return catfact