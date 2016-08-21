-- created by wrxck; based on a plugin by brawl

local lyrics = {}

local utilities = require('mattata.utilities')
local URL = require('socket.url')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function lyrics:init(config)
    lyrics.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('lyrics', true):t('lyric', true):t('sing', true).table
    lyrics.doc = 'Find the lyrics to a song.'
    lyricsnmusic_key = config.lyricsnmusi _key
end

function lyrics:get(text)
    local s = URL.escape(text)
    local r = HTTP.request("http://api.lyricsnmusic.com/songs?api_key=".. lyricsnmusic_key.."&q=" .. s)
    response = JSON.decode(r)
    local reply = ""
    if #response > 0 then
        local result = response[1]
        reply = result.title .. " - " .. result.artist.name .. "\n\n" .. result.snippet .. "\n[Click to read more...](" .. result.url .. ")"
    else
        print('Error connecting to lyricsnmusic.com.')
    end
    return reply
end

function lyrics:action(msg, config, matches)
    local input = utilities.input(msg.text)
    if not input then
        if msg.reply_to_message and msg.reply_to_message.text then
        input = msg.reply_to_message.text
    else
        utilities.send_message(self, msg.chat.id, lyrics.doc, true, msg.message_id, true)
        return
    end
end
utilities.send_reply(self, msg, lyrics:get(input), true)
end

return lyrics