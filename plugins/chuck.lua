--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local chuck = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function chuck:init(configuration)
    chuck.arguments = 'chuck'
    chuck.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('chuck').table
    chuck.help = '/chuck - Generates a Chuck Norris joke!'
end

function chuck:on_inline_query(inline_query, configuration, language)
    local jstr, res = http.request('http://api.icndb.com/jokes/random')
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    local results = json.encode(
        {
            {
                ['type'] = 'article',
                ['id'] = '1',
                ['title'] = jdat.value.joke,
                ['description'] = 'Click to send the result.',
                ['input_message_content'] = {
                    ['message_text'] = jdat.value.joke
                }
            }
        }
    )
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function chuck:on_message(message, configuration, language)
    local jstr, res = http.request('http://api.icndb.com/jokes/random')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    return mattata.send_message(
        message.chat.id,
        jdat.value.joke
    )
end

return chuck