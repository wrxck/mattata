--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local doggo = {}

local mattata = require('mattata')

function doggo:init()
    doggo.commands = mattata.commands(
        self.info.username
    ):command('doggo')
     :command('dog').table
    doggo.help = [[/doggo - Sends a random photo of a dog. Alias: /dog.]]
end

function doggo:on_message(message, configuration)
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    local success = mattata.send_video(
        message.chat.id,
        'http://nosebleed.alienmelon.com/porn/FaciallyDistraughtDogs/dog' .. math.random(62) .. '.gif'
    )
    if not success then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
end

return doggo