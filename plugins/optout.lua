--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local optout = {}

local mattata = require('mattata')
local redis = require('mattata-redis')

function optout:init()
    optout.commands = mattata.commands(
        self.info.username
    ):command('optout')
     :command('optin').table
    optout.help = [[/optout - Removes currently-stored information about you from mattata's database and prevents the storing of future sensitive data (such as messages stored with /save). To re-enable this, and opt-in to the collecting of this data, use /optin.]]
end

function optout:on_message(message)
    if message.text:match('^.optin') then
        redis:del('user:' .. message.from.id .. ':opt_out')
        return mattata.send_reply(
            message,
            'You have opted-in to having data you send collected! Use /optout to opt-out.'
        )
    end
    redis:set(
        'user:' .. message.from.id .. ':opt_out',
        true
    )
    return mattata.send_reply(
        message,
        'You have opted-out of having data you send collected! Use /optin to opt-in.'
    )
end

return optout