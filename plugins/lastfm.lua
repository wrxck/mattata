--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local lastfm = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')

function lastfm:init(configuration)
    assert(
        configuration.keys.lastfm,
        'lastfm.lua requires an API key, and you haven\'t got one configured!'
    )
    lastfm.commands = mattata.commands(self.info.username)
    :command('lastfm')
    :command('np')
    :command('fmset').table
    lastfm.help = '/np <username> - Returns what you are or were last listening to. If you specify a username, info will be returned for that username. /fmset <username> - Sets your last.fm username. Use /fmset -del to delete your current username.'
end

function lastfm.set_username(user, name, language)
    local hash = mattata.get_user_redis_hash(
        user,
        'lastfm'
    )
    redis:hset(
        hash,
        'lastfm',
        name
    )
    return string.format(
        language['lastfm']['1'],
        user.first_name,
        name
    )
end

function lastfm.del_username(user, language)
    local hash = mattata.get_user_redis_hash(
        user,
        'lastfm'
    )
    if redis:hexists(
        hash,
        'lastfm'
    ) then
        redis:hdel(
            hash,
            'lastfm'
        )
        return language['lastfm']['2']
    else
        return language['lastfm']['3']
    end
end

function lastfm.get_username(user)
    local hash = mattata.get_user_redis_hash(
        user,
        'lastfm'
    )
    local name = redis:hget(
        hash,
        'lastfm'
    )
    return name
    or false
end

function lastfm:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    local lastfm_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user='
    local username, results, output
    if inline_query.query == '/np'
    then
        if not lastfm.get_username(inline_query.from)
        then
            return
        end
        username = lastfm.get_username(inline_query.from)
    else
        username = input
    end
    lastfm_url = lastfm_url .. url.escape(username)
    local jstr, res = http.request(lastfm_url)
    local jdat = json.decode(jstr)
    jdat = jdat.recenttracks.track[1]
    or jdat.recenttracks.track
    if inline_query.query == '/np'
    then
        output =  inline_query.from.first_name .. ' (last.fm/user/' .. username .. ')'
    else
        output = username
    end
    if jdat['@attr']
    and jdat['@attr'].nowplaying
    then
        output = string.format(
            language['lastfm']['6'],
            output
        )
    else
        output = string.format(
            language['lastfm']['7'],
            output
        )
    end
    local title = jdat.name
    or language['lastfm']['8']
    local artist = language['lastfm']['8']
    if jdat.artist
    then
        artist = jdat.artist['#text']
    end
    output = output .. artist .. ' - ' .. title
    if jdat.image and jdat.image[4]['#text'] == ''
    then
        local results = json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = artist .. ' - ' .. title,
                    ['description'] = language['lastfm']['9'],
                    ['input_message_content'] = {
                        ['message_text'] = output
                    }
                }
            }
        )
    end
    local results = json.encode(
        {
            {
                ['type'] = 'photo',
                ['id'] = '1',
                ['photo_url'] = jdat.image[4]['#text'],
                ['thumb_url'] = jdat.image[4]['#text'],
                ['caption'] = output
            }
        }
    )
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function lastfm:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if message.text:match('^[/!#]lastfm')
    then
        return mattata.send_reply(
            message,
            lastfm.help
        )
    elseif message.text:match('^[/!#]fmset')
    then
        if not input
        then
            return mattata.send_reply(
                message,
                lastfm.help
            )
        elseif input == '-del'
        then
            return mattata.send_reply(
                message,
                lastfm.del_username(
                    message.from,
                    language
                )
            )
        end
        return mattata.send_reply(
            message,
            lastfm.set_username(
                message.from,
                input,
                language
            )
        )
    end
    local username, output
    if input
    then
        username = input
    elseif lastfm.get_username(
        message.from,
        language
    )
    then
        username = lastfm.get_username(message.from)
    else
        return mattata.send_reply(
            message,
            language['lastfm']['4']
        )
    end
    local jstr, res = http.request('http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user=' .. url.escape(username))
    if res ~= 200
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    local jdat = json.decode(jstr)
    if jdat.error
    then
        return mattata.send_reply(
            message,
            language['lastfm']['4']
        )
    end
    jdat = jdat.recenttracks.track[1]
    or jdat.recenttracks.track
    if not jdat
    then
        return mattata.send_reply(
            message.chat.id,
            language['lastfm']['5']
        )
    end
    if not input
    then
        output = message.from.first_name .. ' (last.fm/user/' .. username .. ')'
    else
        output = input
    end
    if jdat['@attr']
    and jdat['@attr'].nowplaying
    then
        output = string.format(
            language['lastfm']['6'],
            output
        )
    else
        output = string.format(
            language['lastfm']['7'],
            output
        )
    end
    local title = jdat.name
    or language['lastfm']['8']
    local artist = language['lastfm']['8']
    if jdat.artist
    then
        artist = jdat.artist['#text']
    end
    if artist
    and title == language['lastfm']['8']
    then
        mattata.send_chat_action(message.chat.id)
        return mattata.send_message(
            message.chat.id,
            output .. artist .. ' - ' .. title
        )
    end
    if jdat.image
    and jdat.image[1]['#text'] == ''
    then
        return mattata.send_message(
            message.chat.id,
            output .. artist .. ' - ' .. title
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        jdat.image[4]['#text'],
        output .. artist .. ' - ' .. title
    )
end

return lastfm