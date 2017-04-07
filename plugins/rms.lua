--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local rms = {}
local mattata = require('mattata')
local https = require('ssl.https')

function rms:init()
    rms.commands = mattata.commands(
        self.info.username
    ):command('rms').table
    rms.help = '/rms - Sends a random photo of Dr Richard Matthew Stallman.'
end

function rms:on_message(message, configuration)
    local str, res = https.request('https://rms.sexy/img/')
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local results = {}
    for n in str:gmatch('%<a href="(.-)"%>') do
        table.insert(
            results,
            'https://rms.sexy/img/' .. n
        )
    end
    if not next(results) then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        results[math.random(#results)],
        'Holy GNU!'
    )
end

return rms