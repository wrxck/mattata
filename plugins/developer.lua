--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local developer = {}
local mattata = require('mattata')

function developer:init()
    developer.commands = mattata.commands(
        self.info.username
    )
    :command('developer')
    :command('dev').table
    developer.help = '/developer - Connect with the developer through his social media. Alias: /dev.'
end

function developer:on_message(message)
    mattata.forward_message(
        message.chat.id,
        '@wrxck',
        false,
        33
    )
    return mattata.send_message(
        message.chat.id,
        '_"I\'m a web developer/programmer with a love for metal/rock music and spending time with friends!"_',
        'markdown',
        true,
        false,
        nil,
        mattata.inline_keyboard()
        :row(
            mattata.row()
            :url_button(
                'Facebook',
                'https://fb.me/wrxck0'
            )
            :url_button(
                'Messenger',
                'https://m.me/wrxck'
            )
            :url_button(
                'Twitter',
                'https://twitter.com/wrxck__'
            )
        )
        :row(
            mattata.row()
            :url_button(
                'Instagram',
                'https://instagram.com/wrxck_'
            )
            :url_button(
                'Keybase',
                'https://keybase.io/wrxck'
            )
            :url_button(
                'Snapchat',
                'https://www.snapchat.com/add/wrxck0'
            )
        )
        :row(
            mattata.row()
            :url_button(
                'GitHub',
                'https://github.com/wrxck'
            )
            :url_button(
                'Telegram',
                'https://t.me/wrxck0'
            )
            :url_button(
                'Trello',
                'https://trello.com/wrxck'
            )
        )
        :row(
            mattata.row()
            :url_button(
                'Pinterest',
                'https://uk.pinterest.com/wrxck_/'
            )
            :url_button(
                'Google+',
                'https://plus.google.com/u/0/113094819254921723773'
            )
            :url_button(
                'tumblr',
                'https://wrxck0.tumblr.com/'
            )
        )
        :row(
            mattata.row()
            :url_button(
                'Imgur',
                'https://wrxck.imgur.com/'
            )
            :url_button(
                'Instapaper',
                'https://instapaper.com/p/wrxck'
            )
            :url_button(
                'Wikipedia',
                'https://en.wikipedia.org/wiki/User:Wrxck'
            )
        )
    )
end

return developer