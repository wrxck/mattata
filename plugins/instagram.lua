--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local instagram = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function instagram:init(configuration)
    instagram.arguments = 'instagram <user>'
    instagram.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('instagram'):command('ig').table
    instagram.help = configuration.command_prefix .. 'instagram <user> - Sends the profile picture of the given Instagram user. Alias: ' .. configuration.command_prefix .. 'ig.'
end

function instagram:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            instagram.help
        )
    end
    local str, res = http.request('http://igdp.co/' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    elseif str:match('No Instagram Account found%.') or not str:match('%<img src%=%"https%:%/%/(.-)%" class%=%"img%-responsive%"%>') then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'View @' .. input .. ' on Instagram',
                ['url'] = 'https://www.instagram.com/' .. input
            }
        }
    }
    return mattata.send_photo(
        message.chat.id,
        str:match('<img src="https://(.-)" class="img%-responsive">'),
        nil,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return instagram