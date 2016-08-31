-- created by wrxck; based on a plugin by brawl
local lyrics = {}
local functions = require('mattata.functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
local JSON = require('dkjson')
function lyrics:init(configuration)
	lyrics.command = configuration.command_prefix .. 'lyrics <song>'
    lyrics.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lyrics', true).table
    lyrics.doc = 'Find the lyrics to the specified song.'
end
function lyrics:get(text)
	local lyricsnmusic_key = configuration.lyricsnmusic_key
    local s = URL.escape(text)
    local r = HTTP.request("http://api.lyricsnmusic.com/songs?api_key=".. lyricsnmusic_key.."&q=" .. s)
    response = JSON.decode(r)
    local reply = ""
    if #response > 0 then
        local result = response[1]
        reply = result.title .. " - " .. result.artist.name .. "\n\n" .. result.snippet .. "\n[Click to see more...](" .. result.url .. ")"
    else
        print('There was an error whilst connecting to lyricsnmusic.com.')
    end
    return reply
end
function lyrics:action(msg, configuration, matches)
    local input = functions.input(msg.text)
    if not input then
        if msg.reply_to_message and msg.reply_to_message.text then
        input = msg.reply_to_message.text
    else
        functions.send_message(self, msg.chat.id, lyrics.doc, true, msg.message_id, true)
        return
    end
end
functions.send_reply(self, msg, lyrics:get(input), true)
end
return lyrics
