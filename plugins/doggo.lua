--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local doggo = {}

local mattata = require('mattata')

function doggo:init(configuration)
    doggo.arguments = 'doggo'
    doggo.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('doggo').table
    doggo.help = '/doggo - Sends a cute lil\' doggo!'
end

function doggo:on_message(message, configuration, language)
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    local success = mattata.send_video(
        message.chat.id,
        'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(1, 62) .. '.gif'
    )
    if not success then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
end

return doggo