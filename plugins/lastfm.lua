--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local lastfm = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')

function lastfm:init(configuration)
    lastfm.arguments = 'lastfm'
    lastfm.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('lastfm'):command('np'):command('fmset').table
    lastfm.help = configuration.command_prefix .. 'np <username> - Returns what you are or were last listening to. If you specify a username, info will be returned for that username.' .. configuration.command_prefix .. 'fmset <username> - Sets your last.fm username. Use ' .. configuration.command_prefix .. 'fmset -del to delete your current username.'
end

function lastfm.set_username(user, name)
    local hash = mattata.get_user_redis_hash(user, 'lastfm')
    if hash then
        redis:hset(
            hash,
            'lastfm',
            name
        )
        return user.first_name .. '\'s last.fm username has been set to \'' .. name .. '\'.'
    end
end

function lastfm.del_username(user)
    local hash = mattata.get_user_redis_hash(user, 'lastfm')
    if redis:hexists(
        hash,
        'lastfm'
    ) == true then
        redis:hdel(
            hash,
            'lastfm'
        )
        return 'Your last.fm username has been forgotten!'
    else
        return 'You don\'t currently have a last.fm username set!'
    end
end

function lastfm.get_username(user)
    local hash = mattata.get_user_redis_hash(user, 'lastfm')
    if hash then
        local name = redis:hget(hash, 'lastfm')
        if not name or name == 'false' then
            return false
        else
            return name
        end
    end
end

function lastfm:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query)
    local lastfm_url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user='
    local username, results, output
    if inline_query.query == configuration.command_prefix .. 'np' then
        if not lastfm.get_username(inline_query.from) then
            local results = json.encode(
                {
                    {
                        ['type'] = 'article',
                        ['id'] = '1',
                        ['title'] = 'An error occured!',
                        ['description'] = 'Please send ' .. configuration.command_prefix .. 'fmset <username> to me via private chat!',
                        ['input_message_content'] = {
                            ['message_text'] = 'An error occured!\nPlease send ' .. configuration.command_prefix .. 'fmset <username> to me via private chat!'
                        }
                    }
                }
            )
            return mattata.answer_inline_query(
                inline_query.id,
                results
            )
        end
        username = lastfm.get_username(inline_query.from)
    else
        username = input
    end
    lastfm_url = lastfm_url .. url.escape(username)
    local jstr, res = http.request(lastfm_url)
    local jdat = json.decode(jstr)
    jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
    if inline_query.query == configuration.command_prefix .. 'np' then
        output =  inline_query.from.first_name .. ' (last.fm/user/' .. username .. ')'
    else
        output = username
    end
    if jdat['@attr'] and jdat['@attr'].nowplaying then
        output = output .. ' is currently listening to:\n'
    else
        output = output .. ' last listened to:\n'
    end
    local title = jdat.name or 'Unknown'
    local artist = 'Unknown'
    if jdat.artist then
        artist = jdat.artist['#text']
    end
    output = output .. artist .. ' - ' .. title
    if jdat.image[4]['#text'] == '' then
        local results = json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = artist .. ' - ' .. title,
                    ['description'] = 'Click to send the result.',
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
    if message.text_lower:match('^' .. configuration.command_prefix .. 'lastfm$') then
        return mattata.send_reply(
            message,
            lastfm.help
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'fmset') then
        if not input then
            return mattata.send_reply(
                message,
                lastfm.help
            )
        elseif input == '-del' then
            return mattata.send_reply(
                message,
                lastfm.del_username(message.from)
            )
        end
        return mattata.send_reply(
            message,
            lastfm.set_username(message.from, input)
        )
    end
    local username, output
    if input then
        username = input
    elseif lastfm.get_username(message.from) then
        username = lastfm.get_username(message.from)
    else
        return mattata.send_reply(
            message,
            'Please specify your last.fm username or set it with ' .. configuration.command_prefix .. 'fmset.'
        )
    end
    local jstr, res = http.request('http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&api_key=' .. configuration.keys.lastfm .. '&user=' .. url.escape(username))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if jdat.error then
        return mattata.send_reply(
            message,
            'Please specify your last.fm username or set it with ' .. configuration.command_prefix .. 'fmset.'
        )
    end
    jdat = jdat.recenttracks.track[1] or jdat.recenttracks.track
    if not jdat then
        return mattata.send_reply(
            message.chat.id,
            'No history was found for this user.'
        )
    end
    if not input then
        output = message.from.first_name .. ' (last.fm/user/' .. username .. ')'
    else
        output = input
    end
    if jdat['@attr'] and jdat['@attr'].nowplaying then
        output = output .. ' is currently listening to:\n'
    else
        output = output .. ' last listened to:\n'
    end
    local title = jdat.name or 'Unknown'
    local artist = 'Unknown'
    if jdat.artist then
        artist = jdat.artist['#text']
    end
    if artist and title == 'Unknown' then
        mattata.send_chat_action(
            message.chat.id,
            'typing'
        )
        return mattata.send_message(
            message.chat.id,
            output .. artist .. ' - ' .. title
        )
    end
    if jdat.image[1]['#text'] == '' then
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