--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local avatar = {}

local mattata = require('mattata')

function avatar:init(configuration)
    avatar.arguments = 'avatar'
    avatar.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('avatar').table
    avatar.help = '/avatar <user> - Sends the profile photos of the given user, of which can be specified by username or numerical ID. If a number is given after the username, then the nth profile photo is sent (if available).'
end

function avatar:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            avatar.help
        )
    end
    local selected_photo = 1
    if input:match(' %d*$') then
        selected_photo = tonumber(input:match(' (%d*)$'))
        input = input:match('^(.-) %d*$')
    end
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local success = mattata.get_user_profile_photos_pwr(input)
    if not success then
        return mattata.send_reply(
            message,
            [[I couldn't retrieve the profile photos for that user, please ensure you specified a valid username or numerical ID.]]
        )
    elseif success.result.total_count == 0 then
        return mattata.send_reply(
            message,
            [[That user doesn't have any profile photos.]]
        )
    elseif tonumber(selected_photo) < 1 or tonumber(selected_photo) > success.result.total_count then
        return mattata.send_reply(
            message,
            [[That user doesn't have that many profile photos!]]
        )
    end
    local highest_res = success.result.photos[selected_photo][#success.result.photos[selected_photo]].file_id
    local caption = string.format(
        'User: %s\nPhoto: %s/%s\nUse /avatar %s <number> to view a specific photo of this user',
        input,
        selected_photo,
        success.result.total_count,
        input
    )
    return mattata.send_photo(
        message.chat.id,
        highest_res,
        caption
    )
end

return avatar