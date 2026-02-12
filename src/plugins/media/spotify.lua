--[[
    mattata v2.0 - Spotify Plugin
    Searches Spotify for tracks using the client credentials flow.
]]

local plugin = {}
plugin.name = 'spotify'
plugin.category = 'media'
plugin.description = 'Search Spotify for tracks'
plugin.commands = { 'spotify' }
plugin.help = '/spotify <query> - Search Spotify for a track and return song info with a link.'

-- Cache the access token in-memory to avoid re-authenticating on every request
local cached_token = nil
local token_expires = 0

local function get_access_token(config)
    local https = require('ssl.https')
    local json = require('dkjson')
    local ltn12 = require('ltn12')
    local mime = require('mime')

    -- Return cached token if still valid
    if cached_token and os.time() < token_expires then
        return cached_token
    end

    local client_id = config.get('SPOTIFY_CLIENT_ID')
    local client_secret = config.get('SPOTIFY_CLIENT_SECRET')
    if not client_id or not client_secret then
        return nil, 'Spotify credentials have not been configured.'
    end

    local credentials = mime.b64(client_id .. ':' .. client_secret)
    local request_body = 'grant_type=client_credentials'

    local response_body = {}
    local res, code = https.request({
        url = 'https://accounts.spotify.com/api/token',
        method = 'POST',
        sink = ltn12.sink.table(response_body),
        source = ltn12.source.string(request_body),
        headers = {
            ['Authorization'] = 'Basic ' .. credentials,
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = tostring(#request_body)
        }
    })

    if not res or code ~= 200 then
        return nil, 'Failed to authenticate with Spotify.'
    end

    local data = json.decode(table.concat(response_body))
    if not data or not data.access_token then
        return nil, 'Failed to parse Spotify auth response.'
    end

    cached_token = data.access_token
    -- Expire 60 seconds early to be safe
    token_expires = os.time() + (data.expires_in or 3600) - 60
    return cached_token
end

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')
    local ltn12 = require('ltn12')

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Please specify a search query, e.g. <code>/spotify bohemian rhapsody</code>.', 'html')
    end

    local token, err = get_access_token(ctx.config)
    if not token then
        return api.send_message(message.chat.id, err or 'Failed to authenticate with Spotify.')
    end

    local query = url.escape(message.args)
    local search_url = string.format(
        'https://api.spotify.com/v1/search?q=%s&type=track&limit=1',
        query
    )

    local response_body = {}
    local res, code = https.request({
        url = search_url,
        method = 'GET',
        sink = ltn12.sink.table(response_body),
        headers = {
            ['Authorization'] = 'Bearer ' .. token,
            ['Accept'] = 'application/json'
        }
    })

    if code == 401 then
        -- Token expired, clear cache and retry once
        cached_token = nil
        token_expires = 0
        token, err = get_access_token(ctx.config)
        if not token then
            return api.send_message(message.chat.id, err or 'Failed to re-authenticate with Spotify.')
        end
        response_body = {}
        res, code = https.request({
            url = search_url,
            method = 'GET',
            sink = ltn12.sink.table(response_body),
            headers = {
                ['Authorization'] = 'Bearer ' .. token,
                ['Accept'] = 'application/json'
            }
        })
    end

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to search Spotify. Please try again later.')
    end

    local body = table.concat(response_body)
    local data = json.decode(body)
    if not data or not data.tracks or not data.tracks.items or #data.tracks.items == 0 then
        return api.send_message(message.chat.id, 'No tracks found for that query.')
    end

    local track = data.tracks.items[1]
    local track_name = track.name or 'Unknown'
    local track_url = track.external_urls and track.external_urls.spotify or ''
    local album_name = track.album and track.album.name or 'Unknown'

    -- Build artist list
    local artists = {}
    if track.artists then
        for _, artist in ipairs(track.artists) do
            table.insert(artists, artist.name or 'Unknown')
        end
    end
    local artist_str = #artists > 0 and table.concat(artists, ', ') or 'Unknown'

    local output = string.format(
        '<b>%s</b>\nArtist: %s\nAlbum: %s\n<a href="%s">Listen on Spotify</a>',
        tools.escape_html(track_name),
        tools.escape_html(artist_str),
        tools.escape_html(album_name),
        tools.escape_html(track_url)
    )

    return api.send_message(message.chat.id, output, 'html', true)
end

return plugin
