--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local developer = {}
local mattata = require('mattata')

function developer:init()
    developer.commands = mattata.commands(self.info.username)
    :command('developer')
    :command('dev').table
    developer.help = '/developer - Connect with the developer through his social media. Alias: /dev.'
end

function developer:on_message(message, configuration, language)
    mattata.forward_message(
        message.chat.id,
        '@wrxck',
        false,
        33
    )
    return mattata.send_message(
        message.chat.id,
        '_' .. language['developer']['1'] .. '_',
        'markdown',
        true,
        false,
        nil,
        mattata.inline_keyboard()
        :row(
            mattata.row()
            :url_button(
                language['developer']['2'],
                'https://fb.me/wrxck0'
            )
            :url_button(
                language['developer']['3'],
                'https://m.me/wrxck'
            )
            :url_button(
                language['developer']['4'],
                'https://twitter.com/wrxck__'
            )
        )
        :row(
            mattata.row()
            :url_button(
                language['developer']['5'],
                'https://instagram.com/wrxck_'
            )
            :url_button(
                language['developer']['6'],
                'https://keybase.io/wrxck'
            )
            :url_button(
                language['developer']['7'],
                'https://www.snapchat.com/add/wrxck0'
            )
        )
        :row(
            mattata.row()
            :url_button(
                language['developer']['8'],
                'https://github.com/wrxck'
            )
            :url_button(
                language['developer']['9'],
                'https://t.me/wrxck0'
            )
            :url_button(
                language['developer']['10'],
                'https://trello.com/wrxck'
            )
        )
        :row(
            mattata.row()
            :url_button(
                language['developer']['11'],
                'https://uk.pinterest.com/wrxck_/'
            )
            :url_button(
                language['developer']['12'],
                'https://plus.google.com/u/0/113094819254921723773'
            )
            :url_button(
                language['developer']['13'],
                'https://wrxck0.tumblr.com/'
            )
        )
        :row(
            mattata.row()
            :url_button(
                language['developer']['14'],
                'https://wrxck.imgur.com/'
            )
            :url_button(
                language['developer']['15'],
                'https://instapaper.com/p/wrxck'
            )
            :url_button(
                language['developer']['16'],
                'https://en.wikipedia.org/wiki/User:Wrxck'
            )
        )
    )
end

return developer