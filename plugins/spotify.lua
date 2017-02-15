--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local spotify = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function spotify:init()
    spotify.commands = mattata.commands(
        self.info.username
    ):command('spotify').table
    spotify.help = [[/spotify <query> - Searches Spotify for a track matching the given search query and returns the most relevant result.]]
end

function spotify.get_track(jdat)
    if jdat.tracks.total == 0 then
        return false
    end
    local output = ''
    if jdat.tracks.items[1].name then
        if jdat.tracks.items[1].external_urls.spotify then
            output = output .. '<b>Song:</b> <a href="' .. jdat.tracks.items[1].external_urls.spotify .. '">' .. mattata.escape_html(jdat.tracks.items[1].name) .. '</a>\n'
        else
            output = output .. '<b>Song:</b> ' .. mattata.escape_html(jdat.tracks.items[1].name) .. '\n'
        end
    end
    if jdat.tracks.items[1].album.name then
        if jdat.tracks.items[1].album.external_urls.spotify then
            output = output .. '<b>Album:</b> <a href="' .. jdat.tracks.items[1].album.external_urls.spotify .. '">' .. mattata.escape_html(jdat.tracks.items[1].album.name) .. '</a>\n'
        else
            output = output .. '<b>Album:</b> ' .. mattata.escape_html(jdat.tracks.items[1].album.name) .. '\n'
        end
    end
    if jdat.tracks.items[1].album.artists[1].name then
        if jdat.tracks.items[1].album.artists[1].external_urls.spotify then
            output = output .. '<b>Artist:</b> <a href="' .. jdat.tracks.items[1].album.artists[1].external_urls.spotify .. '">' .. mattata.escape_html(jdat.tracks.items[1].album.artists[1].name) .. '</a>\n'
        else
            output = output .. '<b>Artist:</b> ' .. mattata.escape_html(jdat.tracks.items[1].album.artists[1].name) .. '\n'
        end
    end
    if jdat.tracks.items[1].disc_number then
        output = output .. '<b>Disc:</b> ' .. jdat.tracks.items[1].disc_number .. '\n'
    end
    if jdat.tracks.items[1].track_number then
        output = output .. '<b>Track:</b> ' .. jdat.tracks.items[1].track_number .. '\n'
    end
    if jdat.tracks.items[1].popularity then
        output = output .. '<b>Popularity:</b> ' .. jdat.tracks.items[1].popularity
    end
    local preview = false
    if jdat.tracks.items[1].preview_url then
        preview = {
            ['track'] = jdat.tracks.items[1].name,
            ['artist'] = jdat.tracks.items[1].album.artists[1].name,
            ['duration'] = math.floor(tonumber(jdat.tracks.items[1].duration_ms) / 100) or nil,
            ['url'] = jdat.tracks.items[1].preview_url
        }
    end
    return output, preview
end

function spotify:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            spotify.help
        )
    end
    local jstr, res = https.request('https://api.spotify.com/v1/search?q=' .. url.escape(input) .. '&type=track&limit=1')
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local output, preview = spotify.get_track(jdat)
    if not output then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
    if not preview then
        return
    end
    return mattata.send_file_pwr(
        message.chat.id,
        preview.url,
        nil,
        preview.duration,
        preview.artist,
        preview.track,
        nil,
        nil,
        preview.track .. '.mp3'
    )
end

return spotify