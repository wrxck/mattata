--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local facebook = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')

function facebook:init()
    facebook.commands = mattata.commands(
        self.info.username
    ):command('facebook')
     :command('fb').table
    facebook.help = [[/facebook <Facebook username> - Sends the profile picture of the given Facebook user. Alias: /fb.]]
end

function facebook.get_avatar(user)
    local str, res = https.request('https://www.facebook.com/' .. url.escape(user))
    if str == nil then
        return false
    elseif not str:match(',"entity_id":"(.-)"}') then
        return false
    end
    local jstr, code, res = https.request(
        {
            ['url'] = 'https://graph.facebook.com/' .. str:match(',"entity_id":"(.-)"}') .. '/picture?type=large&width=5000&height=5000',
            ['redirect'] = false
        }
    )
    if not res or not res.location then
        return false
    end
    return res.location
end

function facebook:on_inline_query(inline_query, configuration)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local output = facebook.get_avatar(input)
    if not output then
        return mattata.send_inline_article(
            inline_query.id,
            'An error occured!',
            configuration.errors.results
        )
    end
    return mattata.send_inline_photo(
        inline_query.id,
        output
    )
end

function facebook:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            facebook.help
        )
    end
    local output = facebook.get_avatar(input)
    if not output then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    return mattata.send_photo(
        message.chat.id,
        output,
        nil,
        false,
        message.message_id,
        mattata.inline_keyboard():row(
            mattata.row():url_button(
                string.format(
                    'View @%s on Facebook',
                    input
                ),
                'https://www.facebook.com/' .. url.escape(input)
            )
        )
    )
end

return facebook