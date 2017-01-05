--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local ninegag = {}

local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function ninegag:init(configuration)
    ninegag.arguments = 'ninegag'
    ninegag.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('ninegag').table
    ninegag.help = configuration.command_prefix .. 'ninegag - Returns a random image from the latest 9gag posts.'
end

function ninegag:on_inline_query(inline_query, configuration, language)
    local jstr, res = http.request('http://api-9gag.herokuapp.com/')
    if res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    local results_list = {}
    local id = 1
    for n in pairs(jdat) do
        if jdat[n].src and jdat[n].title then
            table.insert(
                results_list,
                {
                    ['type'] = 'photo',
                    ['id'] = tostring(id),
                    ['photo_url'] = jdat[n].src,
                    ['thumb_url'] = jdat[n].src,
                    ['caption'] = jdat[n].title:gsub('"', '\\"')
                }
            )
            id = id + 1
        end
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(results_list)
    )
end

function ninegag:on_message(message, configuration, language)
    local jstr, res = http.request('http://api-9gag.herokuapp.com/')
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
    local jdat = json.decode(jstr)
    local jrnd = math.random(#jdat)
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Read More',
                ['url'] = jdat[jrnd].url
            }
        }
    }
    return mattata.send_photo(
        message.chat.id,
        jdat[jrnd].src,
        jdat[jrnd].title,
        false,
        nil,
        json.encode(keyboard)
    )
end

return ninegag