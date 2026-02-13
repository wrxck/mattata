--[[
    mattata v2.0 - Last.fm Plugin
    Shows now playing / recent tracks from Last.fm.
]]

local plugin = {}
plugin.name = 'lastfm'
plugin.category = 'utility'
plugin.description = 'View your Last.fm now playing and recent tracks'
plugin.commands = { 'lastfm', 'np', 'fmset' }
plugin.help = '/np - Show your currently playing or most recent track.\n/fmset <username> - Link your Last.fm account.\n/lastfm [username] - View recent tracks for a Last.fm user.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')
    local config = require('src.core.config')

    local api_key = config.get('LASTFM_API_KEY')
    if not api_key or api_key == '' then
        return api.send_message(message.chat.id, 'Last.fm is not configured. The bot admin needs to set LASTFM_API_KEY.')
    end

    -- /fmset: link Last.fm username
    if message.command == 'fmset' then
        local username = message.args
        if not username or username == '' then
            return api.send_message(message.chat.id, 'Please provide your Last.fm username. Usage: /fmset <username>')
        end
        -- Remove leading @ if present
        username = username:gsub('^@', '')
        ctx.redis.set('lastfm:' .. message.from.id, username)
        return api.send_message(
            message.chat.id,
            string.format('Your Last.fm username has been set to <b>%s</b>.', tools.escape_html(username)),
            { parse_mode = 'html' }
        )
    end

    -- Determine which Last.fm username to look up
    local fm_user = nil
    if message.command == 'lastfm' and message.args and message.args ~= '' then
        fm_user = message.args:gsub('^@', '')
    else
        fm_user = ctx.redis.get('lastfm:' .. message.from.id)
        if not fm_user then
            return api.send_message(
                message.chat.id,
                'You haven\'t linked your Last.fm account. Use /fmset <username> to link it.'
            )
        end
    end

    -- Fetch recent tracks
    local api_url = string.format(
        'https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=%s&api_key=%s&format=json&limit=1',
        url.escape(fm_user),
        url.escape(api_key)
    )
    local data, status = http.get_json(api_url)
    if not data then
        return api.send_message(message.chat.id, 'Failed to connect to Last.fm. Please try again later.')
    end
    if not data or not data.recenttracks or not data.recenttracks.track then
        return api.send_message(message.chat.id, 'User not found or no recent tracks available.')
    end

    local tracks = data.recenttracks.track
    if type(tracks) ~= 'table' or #tracks == 0 then
        return api.send_message(message.chat.id, 'No recent tracks found for ' .. tools.escape_html(fm_user) .. '.')
    end

    local track = tracks[1]
    local artist = track.artist and (track.artist['#text'] or track.artist.name) or 'Unknown Artist'
    local title = track.name or 'Unknown Track'
    local album = track.album and track.album['#text'] or nil
    local now_playing = track['@attr'] and track['@attr'].nowplaying == 'true'

    local lines = {}
    local tg_name = tools.escape_html(message.from.first_name)
    if now_playing then
        table.insert(lines, string.format('%s is now listening to:', tg_name))
    else
        table.insert(lines, string.format('%s last listened to:', tg_name))
    end
    table.insert(lines, '')
    table.insert(lines, string.format('<b>%s</b> - %s', tools.escape_html(title), tools.escape_html(artist)))
    if album and album ~= '' then
        table.insert(lines, string.format('Album: <i>%s</i>', tools.escape_html(album)))
    end

    -- Fetch playcount for this user
    local user_url = string.format(
        'https://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=%s&api_key=%s&format=json',
        url.escape(fm_user),
        url.escape(api_key)
    )
    local user_data, user_status = http.get_json(user_url)
    if user_data then
        if user_data.user and user_data.user.playcount then
            table.insert(lines, string.format('\nTotal scrobbles: <code>%s</code>', user_data.user.playcount))
        end
    end

    local keyboard = api.inline_keyboard():row(
        api.row():url_button('View on Last.fm', 'https://www.last.fm/user/' .. url.escape(fm_user))
    )

    return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
end

return plugin
