--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local instagram = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function instagram:init(configuration)
    instagram.arguments = 'instagram <user>'
    instagram.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('instagram'):command('ig').table
    instagram.help = '/instagram <user> - Sends the profile picture of the given Instagram user. Alias: /ig.'
end

function instagram:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            instagram.help
        )
    end
    local response = {}

    local str, res = https.request('https://vibbi.com/' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    elseif not str:match('%<img src%=%"https%:%/%/(.-)%"') then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = json.encode(
        {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = '@' .. input .. ' on Instagram',
                        ['url'] = 'https://www.instagram.com/' .. input
                    }
                }
            }
        }
    )
    return mattata.send_photo(
        message.chat.id,
        str:match('%<img src%=%"https%:%/%/(.-)%"'):gsub('%/s150x150%/', '/s320x320/'),
        nil,
        false,
        nil,
        keyboard
    )
end

return instagram