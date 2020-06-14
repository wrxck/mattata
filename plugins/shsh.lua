--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local shsh = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')

function shsh:init()
    shsh.commands = mattata.commands(self.info.username):command('shsh').table
    shsh.help = '/shsh <ecid> - Returns a list of all available SHSH blobs for the given device (specified by its ECID).'
end

function shsh:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        return mattata.send_reply(
            message,
            shsh.help
        )
    end
    local str, res = https.request('https://tsssaver.1conan.com/shsh/' .. url.escape(input) .. '/')
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['shsh']['1']
        )
    end
    local versions = {}
    for n in str:gmatch('%<td%>%<a href=".-" title=".-"%>(.-)/%</a%>%</td%>')
    do
        table.insert(
            versions,
            mattata.symbols.bullet .. ' ' .. n
        )
    end
    return mattata.send_message(
        message.chat.id,
        language['shsh']['2'] .. table.concat(
            versions,
            '\n'
        ),
        nil,
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():url_button(
                language['shsh']['3'],
                'https://tsssaver.1conan.com/shsh/download.php?ecid=' .. url.escape(input)
            )
        )
    )
end

return shsh