--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local lyrics = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function lyrics:init(configuration)
    lyrics.arguments =  'lyrics <query>'
    lyrics.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('lyrics').table
    lyrics.help = configuration.command_prefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics.get_lyrics(input)
    local jstr, res = https.request('https://api.musixmatch.com/ws/1.1/track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. url.escape(input))
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.message.header.available == 0 then
        jstr, res = https.request('https://api.musixmatch.com/ws/1.1/track.search?apikey=' .. configuration.keys.lyrics .. '&q=' .. url.escape(input))
        if res ~= 200 then
            return false
        end
        jdat = json.decode(jstr)
        if jdat.message.header.available == 0 then
            return false
        end
    end
    local artist = mattata.bash_escape(musixmatch.message.body.track_list[1].track.artist_name):gsub('"', '\'')
    local track = mattata.bash_escape(musixmatch.message.body.track_list[1].track.track_name):gsub('"', '\'')
    local output = io.popen('python plugins/lyrics.py "' .. artist .. '" "' .. track .. '"'):read('*all')
    if output == nil or output == '' then
        return false
    end
    local title = '<b>' .. mattata.escape_html(jdat.message.body.track_list[1].track.track_name) .. '</b> ' .. mattata.escape_html(jdat.message.body.track_list[1].track.artist_name) .. '\n🕓 ' .. mattata.format_ms(math.floor(tonumber(jdat.message.body.track_list[1].track.track_length) * 1000)):gsub('^%d%d:', ''):gsub('^0', '') .. '\n\n'
    if output:match('^None\n$') then
        return false
    end
    return title .. mattata.escape_html(output), jdat.message.body.track_list[1].track.track_share_url, musixmatch.message.body.track_list[1].track.track_name, musixmatch.message.body.track_list[1].track.artist_name
end

function lyrics.get_spotify_url(input)
    local jstr, res = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track')
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.tracks.total == 0 then
        return false
    end
    return 'https://open.spotify.com/track/' .. jdat.tracks.items[1].id
end

function lyrics:on_inline_query(inline_query, configuration, language)
    local input = inline_query.query:gsub('^' .. configuration.command_prefix .. 'lyrics', ''):gsub(' - ', ' ')
    local output, musixmatch_url, track, artist = lyrics.get_lyrics(input)
    if not output then
        return
    end
    local jstr, res = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track')
    local keyboard = {}
    if res ~= 200 then
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'musixmatch',
                    ['url'] = musixmatch_url
                }
            }
        }
    end
    local jdat = json.decode(jstr)
    if jdat.tracks.total == 0 then
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'musixmatch',
                    ['url'] = musixmatch_url
                }
            }
        }
    else
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'musixmatch',
                    ['url'] = musixmatch_url
                },
                {
                    ['text'] = 'Spotify',
                    ['url'] = 'https://open.spotify.com/track/' .. jdat.tracks.items[1].id
                }
            }
        }
    end
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = track,
                    ['description'] = artist,
                    ['input_message_content'] = {
                        ['message_text'] = output,
                        ['parse_mode'] = 'html'
                    },
                    ['reply_markup'] = keyboard
                }
            }
        )
    )
end

function lyrics:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            lyrics.help
        )
    end
    input = input:gsub(' - ', ' ')
    mattata.send_chat_action(
        message.chat.id,
        'typing')
    local output, musixmatch_url = lyrics.get_lyrics(input)
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = {}
    local buttons = {
        {
            ['text'] = 'musixmatch',
            ['url'] = musixmatch_url
        }
    }
    local spotify_url = lyrics.get_spotify_url(input)
    if spotify_url then
        table.insert(
            buttons,
            {
                ['text'] = 'Spotify',
                ['url'] = spotify_url
            }
        )
    end
    keyboard.inline_keyboard = {
        buttons
    }
    return mattata.send_message(
        message.chat.id,
        output,
        'html',
        true,
        false,
        nil,
        json.encode(keyboard)
    )
end

return lyrics