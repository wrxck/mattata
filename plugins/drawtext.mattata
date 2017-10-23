--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local drawtext = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function drawtext:init()
    drawtext.commands = mattata.commands(self.info.username):command('drawtext').table
    drawtext.help = '/drawtext <text> - Converts the given text to an image.'
end

function drawtext:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    or (
        message.reply
        and message.reply.text
    )
    if not input
    then
        return mattata.send_reply(
            message,
            drawtext.help
        )
    elseif input:len() > 1000
    then
        input = input:sub(1, 997) .. '...'
    end
    local str, res = http.request('http://api.img4me.com/?text=' .. url.escape(input) .. '&font=comic&size=24')
    if not str
    or res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        str
    )
end

return drawtext