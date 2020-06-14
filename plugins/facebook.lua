--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local facebook = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local redis = require('libs.redis')

function facebook:init()
    facebook.commands = mattata.commands(self.info.username):command('facebook'):command('fbook').table
    facebook.help = '/facebook <Facebook username> - Sends the profile picture of the given Facebook user. Alias: /fbook.'
end

function facebook.get_avatar(user)
    local str = https.request('https://www.facebook.com/' .. url.escape(user))
    if not str or not str:match(',"entity_id":"(.-)"}') then
        return false
    end
    local _, _, res = https.request({
        ['url'] = 'https://graph.facebook.com/' .. str:match(',"entity_id":"(.-)"}') .. '/picture?type=large&width=5000&height=5000',
        ['redirect'] = false
    })
    if not res or not res.location then
        return false
    end
    return res.location
end

function facebook.on_inline_query(_, inline_query, _, language)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local output = facebook.get_avatar(input)
    if not output then
        return mattata.send_inline_article(
            inline_query.id,
            language['facebook']['1'],
            language['errors']['results']
        )
    end
    return mattata.send_inline_photo(inline_query.id, output)
end

function facebook.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        local success = mattata.send_force_reply(message, language['facebook']['2'])
        if success then
            local action = string.format('action:%s:%s', message.chat.id, success.result.message_id)
            redis:set(action, '/facebook')
        end
        return
    elseif input:match('^@.-$') then
        input = input:match('^@(.-)$')
    end
    local output = facebook.get_avatar(input)
    if not output then
        return mattata.send_reply(message, language.errors.results)
    end
    local button_text = string.format(language['facebook']['3'], input)
    local keyboard = mattata.inline_keyboard():row(mattata.row():url_button(button_text, 'https://www.facebook.com/' .. url.escape(input)))
    return mattata.send_photo(message.chat.id, output, nil, false, message.message_id, keyboard)
end

return facebook