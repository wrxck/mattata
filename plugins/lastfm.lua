--[[
    Based on a plugin by topkecleon.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local lastfm = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('libs.redis')

function lastfm:init(configuration)
    assert(configuration.keys.lastfm, 'lastfm.lua requires an API key, and you haven\'t got one configured!')
    lastfm.commands = mattata.commands(self.info.username):command('lastfm'):command('np'):command('fmset').table
    lastfm.help = '/np <username> - Returns what you are or were last listening to. If you specify a username, info will be returned for that username. /fmset <username> - Sets your last.fm username. Use /fmset -del to delete your current username.'
    lastfm.url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key='
end

function lastfm.set_username(user_object, name, language)
    redis:hset('user:' .. user_object.id .. ':info', 'lastfm', name)
    return string.format(language['lastfm']['1'], user_object.first_name, name)
end

function lastfm.del_username(user_id, language)
    if redis:hget('user:' .. user_id .. ':info', 'lastfm') then
        redis:hdel('user:' .. user_id .. ':info', 'lastfm')
        return language['lastfm']['2']
    end
    return language['lastfm']['3']
end

function lastfm.get_username(user_id)
    return redis:hget('user:' .. user_id .. ':info', 'lastfm')
end

function lastfm:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if message.text:match('^[/!#]lastfm') then
        return mattata.send_reply(message, lastfm.help)
    elseif message.text:match('^[/!#]fmset') then
        input = input or message.from.username
        if not input then
            return mattata.send_reply(message, lastfm.help)
        elseif input == '-del' then
            local output = lastfm.del_username(message.from.id, language)
            return mattata.send_reply(message, output)
        end
        local output = lastfm.set_username(message.from, input, language)
        return mattata.send_reply(message, output)
    end
    local username, output
    if input then
        username = input
    elseif lastfm.get_username(message.from.id, language) then
        username = lastfm.get_username(message.from.id)
    else
        return mattata.send_reply(message, language['lastfm']['4'])
    end
    local jstr, res = http.request(lastfm.url .. configuration.keys.lastfm .. '&user=' .. url.escape(username))
    if res ~= 200 then
        return mattata.send_reply(message, language['errors']['connection'])
    end
    local jdat = json.decode(jstr)
    if jdat.error then
        return mattata.send_reply(message, language['lastfm']['4'])
    end
    if not jdat or not jdat.recenttracks then
        return mattata.send_reply(message.chat.id, language['lastfm']['5'])
    end
    jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
    output = input and mattata.escape_html(input) or string.format('<a href="%s">%s</a>', 'https://last.fm/user/' .. url.escape(username), mattata.escape_html(message.from.first_name))
    output = (jdat['@attr'] and jdat['@attr'].nowplaying) and string.format(language['lastfm']['6'], output) or string.format(language['lastfm']['7'], output)
    local title = jdat.name or language['lastfm']['8']
    local artist = jdat.artist and jdat.artist['#text'] or language['lastfm']['8']
    if artist and title ~= jdat.name then
        mattata.send_chat_action(message.chat.id)
        return mattata.send_message(message.chat.id, output .. artist .. ' - ' .. title)
    elseif jdat.image and jdat.image[1]['#text'] == '' then
        return mattata.send_message(message.chat.id, output .. artist .. ' - ' .. title)
    end
    mattata.send_chat_action(message.chat.id, 'upload_photo')
    output = output .. string.format('<a href="%s">%s</a>', jdat.url, artist .. ' - ' .. title)
    return mattata.send_photo(message.chat.id, jdat.image[4]['#text'], output, 'html')
end

return lastfm