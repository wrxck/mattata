--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local myspotify = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('libs.redis')
local ltn12 = require('ltn12')

function myspotify:init(configuration)
    myspotify.commands = mattata.commands(self.info.username):command('myspotify').table
    myspotify.help = '/myspotify - View information about your Spotify account.'
    myspotify.client_id = configuration.keys.spotify.client_id
    myspotify.client_secret = configuration.keys.spotify.client_secret
end

function myspotify.on_new_message(_, message, configuration)
    if redis:get('spotify:' .. message.from.id .. ':refresh_token') and not redis:get('spotify:' .. message.from.id .. ':access_token') then
        local success = myspotify.reauthorise_account(message.from.id, configuration)
        if success then
            redis:set('spotify:' .. message.from.id .. ':access_token', success.access_token)
            redis:expire('spotify:' .. message.from.id .. ':access_token', 3600)
        end
    end
end

function myspotify.get_keyboard(user_id, language, force_playing_state)
    local is_playing = myspotify.get_current_state(user_id, true)
    if force_playing_state then
        is_playing = true
    end
    return mattata.inline_keyboard():row(
        mattata.row()
        :callback_data_button(language['myspotify']['1'], 'myspotify:profile:' .. user_id)
        :callback_data_button(language['myspotify']['2'], 'myspotify:following:' .. user_id)
        :callback_data_button(language['myspotify']['3'], 'myspotify:recentlyplayed:' .. user_id)
    ):row(
        mattata.row():callback_data_button(
            language['myspotify']['4'],
            'myspotify:currentlyplaying:' .. user_id
        ):callback_data_button(
            language['myspotify']['5'],
            'myspotify:toptracks:' .. user_id
        )
    ):row(
        mattata.row():callback_data_button(
            language['myspotify']['6'],
            'myspotify:topartists:' .. user_id
        ):callback_data_button(
            'Playlists',
            'myspotify:playlists:' .. user_id
        )
    ):row(
        mattata.row():callback_data_button(
            myspotify.get_current_track(user_id),
            'myspotify:currentlyplaying:' .. user_id
        )
    ):row(
        mattata.row():callback_data_button(
            utf8.char(9198),
            'myspotify:previous:' .. user_id
        ):callback_data_button(
            is_playing and utf8.char(9208) or utf8.char(9654),
            'myspotify:' .. (is_playing and 'pause:' or 'play:') .. user_id
        ):callback_data_button(
            utf8.char(9197),
            'myspotify:next:' .. user_id
        ):callback_data_button(
            utf8.char(128256),
            'myspotify:shuffle:' .. user_id
        )
    ):row(
        mattata.row():switch_inline_query_current_chat_button(
            'Use Inline Mode',
            '/myspotify'
        ):callback_data_button(
            'Lyrics',
            'myspotify:lyrics:' .. user_id
        )
    )
end

function myspotify.reauthorise_account(user_id)
    local refresh_token = redis:get('spotify:' .. user_id .. ':refresh_token')
    if not refresh_token then
        return false
    end
    local query = string.format('grant_type=refresh_token&refresh_token=%s&client_id=%s&client_secret=%s', url.escape(refresh_token), myspotify.client_id, myspotify.client_secret)
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://accounts.spotify.com/api/token',
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = query:len()
        },
        ['source'] = ltn12.source.string(query),
        ['sink'] = ltn12.sink.table(response)
    })
    local jdat = json.decode(table.concat(response))
    if res ~= 200 or not jdat or jdat.error then
        return false
    end
    return jdat
end

function myspotify.get_top_artists(user_id, language, only_count, only_artists)
    if not user_id or tonumber(user_id) == nil then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/top/artists',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.total or not jdat.items or tonumber(jdat.total) == nil or tonumber(jdat.total) < 1 then
        return language['myspotify']['7']
    elseif only_count then
        return tostring(jdat.total)
    end
    local output = {}
    if not only_artists then
        table.insert(output, '<b>' .. language['myspotify']['8'] .. '</b>')
    end
    for i = 1, tonumber(jdat.total) do
        if jdat.items[i] then
            if jdat.items[i].external_urls then
                jdat.items[i].spotify = jdat.items[i].external_urls.spotify
            end
            local link = mattata.create_link(jdat.items[i].name, jdat.items[i].spotify, 'html')
            table.insert(output, mattata.symbols.bullet .. ' ' .. link)
        end
    end
    return table.concat(output, '\n')
end

function myspotify.get_top_tracks(user_id, language, only_count, only_tracks)
    if not user_id or tonumber(user_id) == nil then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/top/tracks',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.total or tonumber(jdat.total) == nil or tonumber(jdat.total) < 1 then
        return language['myspotify']['9']
    elseif only_count then
        return tostring(jdat.total)
    end
    local output = {}
    if not only_tracks then
        table.insert(output, '<b>' .. language['myspotify']['10'] .. '</b>')
    end
    for _, v in pairs(jdat.items) do
        local artists = {}
        for n, artist in pairs(v.artists) do
            local separator = ' — '
            if #v.artists > 1 then
                separator = '\n    ├ '
                if n == #v.artists then
                    separator = '\n    └ '
                end
            end
            if artist.external_urls.spotify then
                artist.spotify = artist.external_urls.spotify
            end
            local link = mattata.create_link(artist.name, artist.spotify, 'html')
            table.insert(artists, separator .. link)
        end
        if v.external_urls then
            v.spotify = v.external_urls.spotify
        end
        local link = mattata.create_link(v.name, v.spotify, 'html')
        table.insert(output, mattata.symbols.bullet .. ' ' .. link .. table.concat(artists))
    end
    return table.concat(output, '\n')
end

function myspotify.get_following(user_id, language, only_count, only_followers)
    if not user_id or tonumber(user_id) == nil then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/following?type=artist',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.artists or tonumber(jdat.artists.total) == nil or tonumber(jdat.artists.total) < 1 then
        return language['myspotify']['11']
    elseif only_count then
        return tostring(jdat.artists.total)
    end
    local output = {}
    if not only_followers then
        table.insert(output, '<b>' .. language['myspotify']['12'] .. '</b>')
    end
    for _, v in pairs(jdat.artists.items) do
        if v.external_urls then
            v.spotify = v.external_urls.spotify
        end
        local link = mattata.create_link(v.name, v.spotify, 'html')
        local total = string.format(' [%s]', v.followers.total or 0)
        table.insert(output, mattata.symbols.bullet .. ' ' .. link .. total)
    end
    return table.concat(output, '\n')
end

function myspotify.get_recently_played(user_id, language, only_count)
    if not user_id or tonumber(user_id) == nil then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/recently-played',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat.items or #jdat.items < 1 then
        return language['myspotify']['13']
    elseif only_count then
        return tostring(#jdat.items)
    end
    local artists = {}
    for _, v in pairs(jdat.items[1].track.artists) do
        if v.external_urls.spotify then
            v.spotify = v.external_urls.spotify
        end
        local link = mattata.create_link(v.name, v.spotify)
        table.insert(artists, link)
    end
    if jdat.items[1].track.external_urls.spotify then
        jdat.items[1].track.spotify = jdat.items[1].track.external_urls.spotify
    end
    local year, month, day, hours, minutes = jdat.items[1].played_at:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):%d%d%.%d%d%dZ$')
    return string.format(language['myspotify']['14'], utf8.char(127925),
        mattata.create_link(
            jdat.items[1].track.name,
            jdat.items[1].track.spotify
        ),
        utf8.char(127897),
        #artists == 0
        and '—'
        or table.concat(
            artists,
            ', '
        ),
        utf8.char(128338),
        tostring(hours),
        tostring(minutes),
        tostring(day),
        tostring(month),
        tostring(year)
    )
end

function myspotify.get_currently_playing(user_id, language)
    if not user_id
    or tonumber(user_id) == nil
    or not redis:get('spotify:' .. user_id .. ':access_token')
    then
        return false
    end
    local response = {}
    local _, res = https.request(
        {
            ['url'] = 'https://api.spotify.com/v1/me/player/currently-playing',
            ['method'] = 'GET',
            ['headers'] = {
                ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
            },
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if res ~= 200
    then
        if res == 202
        then
            return language['myspotify']['15']
        end
        return false
    end
    local jdat = json.decode(
        table.concat(response)
    )
    if not jdat
    or not jdat.is_playing
    or tostring(jdat.is_playing) ~= 'true'
    then
        return language['myspotify']['16']
    end
    local artists = {}
    for _, v in pairs(jdat.item.artists)
    do
        if v.external_urls.spotify
        then
            v.spotify = v.external_urls.spotify
        end
        table.insert(
            artists,
            mattata.create_link(
                v.name,
                v.spotify
            )
        )
    end
    if jdat.item.external_urls.spotify
    then
        jdat.item.spotify = jdat.item.external_urls.spotify
    end
    return '<b>' .. language['myspotify']['17'] .. '</b>\n' .. mattata.create_link(
        '💽',
        jdat.item.album.images[1].url
    ) .. ' ' .. mattata.create_link(
        jdat.item.name,
        jdat.item.spotify
    ) .. '\n🎙 ' .. table.concat(
        artists,
        ', '
    )
end

function myspotify.get_devices(user_id, language)
    if not user_id or tonumber(user_id) == nil or not redis:get('spotify:' .. user_id .. ':access_token') then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/devices',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        if res == 202 then
            return language['myspotify']['15']
        end
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat or not jdat.devices or not jdat.devices[1] then
        return 'No devices were found.'
    end
    local devices = {}
    for _, v in pairs(jdat.devices) do
        local device = string.format('%s %s [%s]', mattata.symbols.bullet, v.name, v.type)
        table.insert(devices, device)
    end
    return table.concat(devices, '\n')
end

function myspotify.get_playlists(user_id, language, only_count, only_playlists)
    if not user_id or tonumber(user_id) == nil then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/playlists',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat or not jdat.items or not jdat.items[1] then
        return 'You don\'t appear to have any playlists.'
    elseif only_count then
        return tostring(jdat.total)
    end
    local output = {}
    if not only_playlists then
        table.insert(output, '<b>Your Playlists</b>')
    end
    for _, v in pairs(jdat.items) do
        if v.external_urls then
            v.spotify = v.external_urls.spotify
        end
        local link = mattata.create_link(v.name, v.spotify, 'html')
        local tracks = string.format(' [%s tracks]', v.tracks.total or 0)
        table.insert(output, mattata.symbols.bullet .. ' ' .. link .. tracks)
    end
    return table.concat(output, '\n')
end

function myspotify.get_user_info(user_id, language)
    if not user_id or not redis:get('spotify:' .. user_id .. ':access_token') then
        return false
    end
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat or jdat.error then
        return false
    end
    local name = jdat.display_name or jdat.id
    name = mattata.create_link(name, jdat.external_urls.spotify, 'html')
    local followers = mattata.create_link(jdat.followers.total, jdat.followers.href, 'html')
    if jdat.images and jdat.images[#jdat.images] then
        jdat.images = jdat.images[#jdat.images].url
    end
    local product = jdat.product:gsub('^%l', string.upper)
    local devices = myspotify.get_devices(user_id, language)
    local avatar = mattata.create_link(utf8.char(128100), jdat.images)
    return string.format('%s %s [%s]\nSpotify %s user\n\n<b>Devices:</b>\n%s', avatar, name, followers, product, devices)
end

function myspotify.get_current_state(user_id, is_playing)
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat or jdat.error then
        return false
    elseif is_playing then
        is_playing = tostring(jdat.is_playing)
        if is_playing == 'true' then
            return true
        end
        return false
    end
    return jdat
end

function myspotify.previous_track(user_id)
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/previous',
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'Playing previous track...'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'I could not find any devices.'
    end
    return false
end

function myspotify.next_track(user_id)
    if not user_id or not redis:get('spotify:' .. user_id .. ':access_token') then
        return false
    end
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/next',
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'Playing next track...'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'I could not find any devices.'
    end
    return false
end

function myspotify.play(user_id)
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/play',
        ['method'] = 'PUT',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'Resuming track...'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'Your device is temporarily unavailable...'
    elseif res == 404 then
        return 'No devices were found!'
    end
    return false
end

function myspotify.pause(user_id)
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/pause',
        ['method'] = 'PUT',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'Pausing track...'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'Your device is temporarily unavailable...'
    elseif res == 404 then
        return 'No devices were found!'
    end
    return false
end

function myspotify.get_current_artist(user_id)
    local current = myspotify.get_current_state(user_id)
    if not current or not current.item or not current.item.artists or not current.is_playing then
        return false
    end
    return current.item.artists[1].name
end

function myspotify.get_current_track(user_id, language, only_track)
    local current = myspotify.get_current_state(user_id)
    if not current or not current.item or tostring(current.is_playing) == 'false' then
        if only_track then
            return '—'
        end
        return 'Now playing: —'
    end
    if only_track then
        return current.item.name
    end
    local artist = myspotify.get_current_artist(user_id)
    if artist then
        current.item.name = artist .. ' – ' .. current.item.name
    end
    return current.item.name
end

function myspotify.get_username(user_id)
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me',
        ['method'] = 'GET',
        ['headers'] = {
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        },
        ['sink'] = ltn12.sink.table(response)
    })
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    if not jdat or jdat.error then
        return false
    end
    return jdat.id
end

function myspotify.shuffle(user_id)
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/shuffle?state=true',
        ['method'] = 'PUT',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'Shuffling your music...'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'Your device is temporarily unavailable...'
    elseif res == 404 then
        return 'No devices were found!'
    end
    return false
end

function myspotify.set_volume(user_id, volume)
    if not volume or tonumber(volume) == nil or tonumber(volume) < 0 or tonumber(volume) > 100 then
        return 'That\'s not a valid volume. Please specify a number between 0 and 100.'
    end
    local _, res = https.request({
        ['url'] = 'https://api.spotify.com/v1/me/player/volume?volume_percent=' .. volume,
        ['method'] = 'PUT',
        ['headers'] = {
            ['Content-Length'] = 0,
            ['Authorization'] = 'Bearer ' .. redis:get('spotify:' .. user_id .. ':access_token')
        }
    })
    if res == 200 or res == 204 then
        return 'The volume has been set to ' .. volume .. '%!'
    elseif res == 403 then
        return 'You are not a premium user!'
    elseif res == 202 then
        return 'Your device is temporarily unavailable...'
    elseif res == 404 then
        return 'No devices were found!'
    end
    return 'An error occured, meaning I was unable to set the volume.'
end

function myspotify.on_inline_query(_, inline_query, _, language)
    if not redis:get('spotify:' .. inline_query.from.id .. ':access_token') and redis:get('spotify:' .. inline_query.from.id .. ':refresh_token') then
        local success = myspotify.reauthorise_account(inline_query.from.id)
        if not success then
            return false
        end
        redis:set('spotify:' .. inline_query.from.id .. ':access_token', success.access_token)
        redis:expire('spotify:' .. inline_query.from.id .. ':access_token', 3600)
    end
    local output = myspotify.get_user_info(inline_query.from.id, language)
    if not output then
        return false
    end
    local description = myspotify.help:match('%- (.-)$')
    local title = '@' .. myspotify.get_username(inline_query.from.id)
    local keyboard = myspotify.get_keyboard(inline_query.from.id, language)
    return mattata.send_inline_article(inline_query.id, title, description, output, 'html', keyboard)
end

function myspotify.on_callback_query(_, callback_query, message, configuration, language)
    local action, user_id = callback_query.data:match('^(.-):(%d+)$')
    if not user_id then
        return mattata.answer_callback_query(callback_query.id, 'This message is using an old version of this plugin, please request a new one by sending /myspotify!', true)
    end
    user_id = tonumber(user_id)
    callback_query.data = action
    if callback_query.from.id ~= user_id then
        return mattata.answer_callback_query(callback_query.id, 'You are not allowed to use this!')
    elseif callback_query.data == 'nil' then
        return mattata.answer_callback_query(callback_query.id)
    elseif not redis:get('spotify:' .. user_id .. ':access_token') then
        local success = myspotify.reauthorise_account(user_id, configuration)
        if not success then
            return mattata.answer_callback_query(callback_query.id, language['myspotify']['18'])
        end
        redis:set('spotify:' .. user_id .. ':access_token', success.access_token)
        redis:expire('spotify:' .. user_id .. ':access_token', 3600)
        mattata.answer_callback_query(callback_query.id, language['myspotify']['19'], true)
    end
    local output
    if callback_query.data == 'profile' then
        output = myspotify.get_user_info(user_id, language)
    elseif callback_query.data == 'following' then
        output = myspotify.get_following(user_id, language)
    elseif callback_query.data == 'toptracks' then
        output = myspotify.get_top_tracks(user_id, language)
    elseif callback_query.data == 'topartists' then
        output = myspotify.get_top_artists(user_id, language)
    elseif callback_query.data == 'recentlyplayed' then
        output = myspotify.get_recently_played(user_id, language)
    elseif callback_query.data == 'currentlyplaying' then
        output = myspotify.get_currently_playing(user_id, language)
    elseif callback_query.data == 'playlists' then
        output = myspotify.get_playlists(user_id, language)
    elseif callback_query.data == 'previous' then
        output = myspotify.previous_track(user_id, language) or language.errors.generic
        mattata.answer_callback_query(callback_query.id, output)
    elseif callback_query.data == 'next' then
        output = myspotify.next_track(user_id, language) or language.errors.generic
        mattata.answer_callback_query(callback_query.id, output)
    elseif callback_query.data == 'play' then
        output = myspotify.play(user_id, language) or language.errors.generic
        mattata.answer_callback_query(callback_query.id, output)
    elseif callback_query.data == 'pause' then
        output = myspotify.pause(user_id, language) or language.errors.generic
        mattata.answer_callback_query(callback_query.id, output)
    elseif callback_query.data == 'shuffle' then
        output = myspotify.shuffle(user_id, language)
        if output then
            myspotify.next_track(user_id, language)
        else
            output = language.errors.generic
        end
        mattata.answer_callback_query(callback_query.id, output)
    elseif callback_query.data == 'lyrics' then
        local artist = myspotify.get_current_artist(user_id)
        local track = myspotify.get_current_track(user_id, language, true)
        if artist then
            track = artist .. ' - ' .. track
        end
        local lyrics = require('plugins.lyrics')
        output = lyrics.send_request(track)
    end
    output = output or language.errors.generic
    local preview = callback_query.data == 'currentlyplaying' and false or true
    local keyboard = myspotify.get_keyboard(user_id, language)
    return mattata.edit_message_text(message.chat.id, message.message_id, output, 'html', preview, keyboard)
end

function myspotify.on_message(_, message, configuration, language)
    local input = mattata.input(message.text)
    if input and (input:lower() == 'reset' or input:lower() == 'revoke') then
        redis:del('spotify:' .. message.from.id .. ':access_token')
        redis:del('spotify:' .. message.from.id .. ':refresh_token')
        return mattata.send_reply(message, 'I have cleared your current account! Use /myspotify to link a new account.')
    elseif not redis:get('spotify:' .. message.from.id .. ':access_token') then
        if redis:get('spotify:' .. message.from.id .. ':refresh_token') then
            local wait_message = mattata.send_message(message.chat.id, language['myspotify']['20'])
            local success = myspotify.reauthorise_account(message.from.id, configuration)
            if not success then
                return mattata.edit_message_text(message.chat.id, wait_message.result.message_id, language['myspotify']['18'])
            end
            redis:set('spotify:' .. message.from.id .. ':access_token', success.access_token)
            redis:expire('spotify:' .. message.from.id .. ':access_token', 3600)
            mattata.edit_message_text(message.chat.id, wait_message.result.message_id, language['myspotify']['19'])
        else
            local success = mattata.send_force_reply(
                message,
                string.format(
                    language['myspotify']['21'],
                    url.escape(myspotify.client_id),
                    url.escape(myspotify.redirect_uri),
                    myspotify.redirect_uri
                ),
                'markdown'
            )
            if success then
                mattata.set_command_action(message.chat.id, success.result.message_id, '/authspotify')
            end
            return
        end
    end
    local output = myspotify.get_user_info(message.from.id, language)
    if not output then
        return mattata.send_reply(message, language.errors.connection)
    end
    local keyboard = myspotify.get_keyboard(message.from.id, language)
    return mattata.send_message(message.chat.id, output, 'html', true, false, nil, keyboard)
end

return myspotify