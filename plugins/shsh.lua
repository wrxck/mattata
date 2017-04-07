--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local shsh = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')

function shsh:init()
    shsh.commands = mattata.commands(
        self.info.username
    ):command('shsh').table
    shsh.help = '/shsh <ecid> - Returns a list of all available SHSH blobs for the given device (specified by its ECID).'
end

function shsh:on_message(message, configuration)
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
            'I couldn\'t fetch any SHSH blobs for that ECID, please ensure it\'s valid and you have saved them using https://tsssaver.1conan.com.'
        )
    end
    local versions = {}
    for n in str:gmatch('%<td%>%<a href=".-" title=".-"%>(.-)/%</a%>%</td%>') do
        table.insert(
            versions,
            mattata.symbols.bullet .. ' ' .. n
        )
    end
    return mattata.send_message(
        message.chat.id,
        'SHSH blobs for that device are available for the following versions of iOS:\n' .. table.concat(
            versions,
            '\n'
        ),
        nil,
        true,
        false,
        nil,
        mattata.inline_keyboard()
        :row(
            mattata.row()
            :url_button(
                'Download .zip',
                'https://tsssaver.1conan.com/shsh/download.php?ecid=' .. url.escape(input)
            )
        )
    )
end

return shsh