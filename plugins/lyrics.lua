--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local lyrics = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local html = require('htmlEntities')
local configuration = require('configuration')

function lyrics:init(configuration)
    assert(
        configuration.keys.lyrics,
        'lyrics.lua requires an API key, and you haven\'t got one configured!'
    )
    lyrics.arguments =  'lyrics <query>'
    lyrics.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('lyrics').table
    lyrics.help = '/lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics.search_lyrics_wikia(artist, track)
    local str, res = http.request(
        string.format(
            'http://lyrics.wikia.com/wiki/%s:%s',
            url.escape(artist:gsub('%s', '_')),
            url.escape(track:gsub('%s', '_'))
        )
    )
    if res ~= 200 then
        return false
    end
    str = str:match('%<div class%=%\'lyricbox%\'%>(.-)%<div class%=%\'lyricsbreak%\'%>')
    if not str or str:match('[Uu]nfortunately%,? we are not licensed%.?') then
        return false
    end
    str = str:gsub('%<br ?%/?%>', '\n'):gsub('%<%/?b%>', '')
    return html.decode(str)
end

function lyrics.search_az_lyrics(artist, track)
    local response = {}
    local _, res = http.request(
        {
            ['url'] = string.format(
                'www.azlyrics.com/lyrics/%s/%s.html',
                url.escape(artist:lower():gsub('%s', '')),
                url.escape(track:lower():gsub('%s', ''))
            ),
            ['method'] = 'GET',
            ['headers'] = {
                ['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                ['Accept-Encoding'] = 'gzip, deflate, sdch',
                ['Accept-Language'] = 'en-US,en;q=0.8',
                ['Cache-Control'] = 'max-age=0',
                ['Connection'] = 'keep-alive',
                ['Cookie'] = '__utma=190584827.1320932754.1464087709.1474798020.1475005190.4; __utmz=190584827.1475005190.4.4.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); __atuvc=0%7C49%2C0%7C50%2C0%7C1%2C1%7C52%2C1%7C2; __atuvs=5877c3ffd3f17411000',
                ['DNT'] = '1',
                ['Host'] = 'www.azlyrics.com',
                ['Upgrade-Insecure-Requests'] = '1',
                ['User-Agent'] = 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Mobile Safari/537.36'
            },
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200 then
        return false
    end
    local str = table.concat(response):match('%<%!%-%- Usage of azlyrics%.com content by any third%-party lyrics provider is prohibited by our licensing agreement%. Sorry about that%. %-%-%>(.-)%<%/div%>'):gsub('%<br ?%/?%>', ''):gsub('%<%/?b%>', '')
    if not str then
        return false
    end
    return html.decode(str)
end

function lyrics.search_plyrics(artist, track)
    local response = {}
    local _, res = http.request(
        {
            ['url'] = string.format(
                'http://www.plyrics.com/lyrics/%s/%s.html',
                url.escape(artist:lower():gsub('%s', '')),
                url.escape(track:lower():gsub('%s', ''))
            ),
            ['method'] = 'GET',
            ['headers'] = {
                ['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                ['Accept-Encoding'] = 'gzip, deflate, sdch',
                ['Accept-Language'] = 'en-US,en;q=0.8',
                ['Cache-Control'] = 'max-age=0',
                ['Connection'] = 'keep-alive',
                ['Cookie'] = '__utmt=1; __utma=179262907.1714206337.1484225238.1484225238.1484225238.1; __utmb=179262907.1.10.1484225238; __utmc=179262907; __utmz=179262907.1484225238.1.1.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided)',
                ['Host'] = 'www.plyrics.com',
                ['Upgrade-Insecure-Requests'] = '1',
                ['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'
            },
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200 then
        return false
    end
    str = table.concat(response):match('%<%!%-%- start of lyrics %-%-%>(.-)%<%!%-%- end of lyrics %-%-%>')
    if not str then
        return false
    end
    return html.decode(str:gsub('%<br ?%/?%>', ''):gsub('%<%/?b%>', ''))
end

function lyrics.search_lyrics(artist, track)
    local success = lyrics.search_lyrics_wikia(
        artist,
        track
    )
    if not success then
        success = lyrics.search_plyrics(
            artist,
            track
        )
    end
    if not success then
        success = lyrics.search_az_lyrics(
            artist,
            track
        )
    end
    if not success then
        return false
    end
    return success
end

function lyrics.send_request(input)
    local search_url = string.format(
        'https://api.musixmatch.com/ws/1.1/track.search?apikey=%s&s_track_rating=desc',
        configuration.keys.lyrics
    )
    if input:match('^.- %- .-$') then -- Perform a more specific search if the user searches for lyrics in the format artist - song.
        search_url = string.format(
            '%s&q_artist=%s&q_track=%s',
            search_url,
            url.escape(input:match('^(.-) %- .-$')),
            url.escape(input:match('^.- %- (.-)$'))
        )
    else
        search_url = string.format(
            '%s&q_track=%s',
            search_url,
            url.escape(input)
        )
    end
    local jstr, res = https.request(search_url)
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.message.header.available == 0 then
        jstr, res = https.request(
            string.format(
                'https://api.musixmatch.com/ws/1.1/track.search?apikey=%s&s_track_rating=desc&q=%s',
                configuration.keys.lyrics,
                url.escape(input)
            )
        )
        if res ~= 200 then
            return false
        end
        jdat = json.decode(jstr)
        if jdat.message.header.available == 0 then
            return false
        end
    end
    local artist = jdat.message.body.track_list[1].track.artist_name
    local track = jdat.message.body.track_list[1].track.track_name
    track = track:match('^(.-) %(.-%) %[.-%]$') or track:match('^(.-) %(.-%)$') or track
    local output = lyrics.search_lyrics(
        artist,
        track
    )
    if not output then
        local jstr_lyrics, res_lyrics = https.request(
            string.format(
                'https://api.musixmatch.com/ws/1.1/track.lyrics.get?apikey=%s&track_id=%s',
                configuration.keys.lyrics,
                jdat.message.body.track_list[1].track.track_id
            )
        )
        if res_lyrics ~= 200 then
            return false
        end
        local jdat_lyrics = json.decode(jstr_lyrics)
        if jdat_lyrics.message.header.status_code ~= 200 then
            return false
        end
        output = jdat_lyrics.message.body.lyrics.lyrics_body:match('^(.-)\n\n[%*]+') or jdat_lyrics.message.body.lyrics.lyrics_body
    end
    if output:len() > 4000 then -- If the lyrics are REALLY long, trim them so they'll fit in a single message (this is only a temporary solution)
        output = output:sub(1, 4000) .. '...'
    end
    output = output:gsub('\\', '')
    output = string.format(
        '<b>%s</b> %s\n🕓 %s\n\n%s',
        mattata.escape_html(track),
        mattata.escape_html(artist),
        mattata.format_ms(math.floor(tonumber(jdat.message.body.track_list[1].track.track_length) * 1000)):gsub('^%d%d:', ''):gsub('^0', ''),
        mattata.escape_html(output)
    )
    return output, artist, track
end

function lyrics.search_spotify(input)
    local jstr, res = https.request(
        string.format(
            'https://api.spotify.com/v1/search?q=%s&type=track',
            url.escape(input)
        )
    )
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if not jdat.tracks or jdat.tracks.total == 0 then
        return false
    end
    return 'https://open.spotify.com/track/' .. jdat.tracks.items[1].id
end

function lyrics.get_keyboard(artist, track)
    local spotify_url = lyrics.search_spotify(artist .. ' ' .. track)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    if spotify_url then
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = 'Spotify',
                    ['url'] = spotify_url
                }
            }
        )
        return json.encode(keyboard)
    end
    return nil
end

function lyrics:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local output, artist, track = lyrics.send_request(input)
    if not output then
        return
    end
    local keyboard = lyrics.get_keyboard(
        artist,
        track
    )
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
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local output, artist, track = lyrics.send_request(input)
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    local keyboard = lyrics.get_keyboard(artist, track)
    return mattata.send_message(
        message.chat.id,
        output,
        'html',
        true,
        false,
        nil,
        keyboard
    )
end

return lyrics