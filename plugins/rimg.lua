--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local rimg = {}

local mattata = require('mattata')

function rimg:init()
    rimg.commands = mattata.commands(
        self.info.username
    ):command('rimg').table
    rimg.help = [[/rimg <width> [height] [-g/-b] - Sends a random image which matches the dimensions provided, in pixels. If only 1 dimension is given, the other is assumed to be the same. Append -g to the end of your message to return a grayscale photo, or append -b to the end of your message to return a blurred photo. The maximum value for each dimension is 5000, and the minimum for each is 250.]]
end

function rimg:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            rimg.help
        )
    end
    local width = 0
    local height = 0
    local blur = false
    local url = 'https://unsplash.it/'
    if input:match(' %-g$') then
        url = url .. 'g/'
        input = input:gsub(' %-g$', '')
    elseif input:match(' %-b$') then
        blur = true
        input = input:gsub(' %-b$', '')
    end
    if not input:match('^%d+$') and not input:match('^%d+ %d+$') then
        return mattata.send_reply(
            message,
            'You have specified invalid dimensions. Use /rimg to view the command usage.'
        )
    elseif input:match('^%d+$') then
        width = tonumber(
            input:match('^(%d+)$')
        )
        height = width
    elseif input:match('^%d+ %d+$') then
        width = tonumber(
            input:match('^(%d+) %d+$')
        )
        height = tonumber(
            input:match('^%d+ (%d+)$')
        )
    end
    if width > 5000 or width < 250 or height > 5000 or height < 250 then
        return mattata.send_reply(
            message,
            'You have specified invalid dimensions. Use /rimg to view the command usage.'
        )
    end
    url = string.format(
        '%s%s/%s/?random',
        url,
        width,
        height
    )
    if blur then
        url = url .. '&blur'
    end
    local success = mattata.send_photo(
        message.chat.id,
        url
    )
    if not success then
        return mattata.send_reply(
            message,
            'There was an issue sending the image you requested. Please check your command syntax and try again.'
        )
    end
    return
end

return rimg