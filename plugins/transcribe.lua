--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local transcribe = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('libs.redis')

function transcribe:init()
    transcribe.commands = mattata.commands(self.info.username):command('transcribe'):command('tts').table
    transcribe.help = '/transcribe - Transcribes the replied-to voice message using wit.ai. Alias: /tts.'
end

function transcribe.is_valid(message)
    local voice = message.reply and message.reply.voice or message.voice
    if voice.mime_type ~= 'audio/ogg' then
        return false
    elseif voice.duration > 20 then
        return false
    elseif voice.file_size >= 20000000 then
        return false
    end
    return true
end

function transcribe.on_new_message(_, message)
    if message.chat.type == 'private' or not message.voice or not transcribe.is_valid(message) then
        return false
    end
    redis:set('transcribe:' .. message.chat.id .. ':' .. message.message_id, json.encode(message))
    return
 end

 function transcribe.on_message(_, message)
    if not message.reply then
        return mattata.send_reply(message, transcribe.help)
    elseif not message.reply.voice then
        return mattata.send_reply(message, 'You can only use this message in reply to voice messages!')
    elseif not transcribe.is_valid(message) then
        return mattata.send_reply(message, 'The voice message must meet the following conditions:\n1. It must be 20 seconds or less in length\n2. It must be 20MB or less in file size\n3. It must be of the audio/ogg MIME type')
    end
    return redis:set('transcribe:' .. message.chat.id .. ':' .. message.message_id, json.encode(message.reply))
end

return transcribe