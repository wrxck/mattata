--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local cats = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function cats:init(configuration)
    assert(
        configuration.keys.cats,
        'cats.lua requires an API key, and you haven\'t got one configured!'
    )
    cats.arguments = 'cat'
    cats.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('cat'):command('sarah').table
    cats.help = configuration.command_prefix .. 'cat - A random picture of a cat!'
end

function cats:on_inline_query(inline_query, configuration, language)
    local str, res = http.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
    str = str:match('<img src="(.-)">')
    if res ~= 200 then
        return
    end
    local results = json.encode(
        {
            {
                ['type'] = 'photo',
                ['id'] = '1',
                ['photo_url'] = str,
                ['thumb_url'] = str,
                ['caption'] = 'Meow!'
            }
        }
    )
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function cats:on_message(message, configuration, language)
    local str, res = http.request('http://thecatapi.com/api/images/get?format=html&type=jpg&api_key=' .. configuration.keys.cats)
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        str:match('<img src="(.-)">'),
        'Meow!'
    )
end

return cats