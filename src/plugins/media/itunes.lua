--[[
    mattata v2.0 - iTunes Plugin
    Searches the iTunes Store for tracks.
]]

local plugin = {}
plugin.name = 'itunes'
plugin.category = 'media'
plugin.description = 'Search the iTunes Store for tracks'
plugin.commands = { 'itunes' }
plugin.help = '/itunes <query> - Search iTunes for a track and return song info with pricing.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Please specify a search query, e.g. <code>/itunes imagine dragons believer</code>.', { parse_mode = 'html' })
    end

    local query = url.escape(message.args)
    local api_url = string.format(
        'https://itunes.apple.com/search?term=%s&media=music&entity=song&limit=1',
        query
    )

    local data, code = http.get_json(api_url)

    if not data then
        return api.send_message(message.chat.id, 'Failed to search iTunes. Please try again later.')
    end
    if not data or not data.results or #data.results == 0 then
        return api.send_message(message.chat.id, 'No results found for that query.')
    end

    local track = data.results[1]
    local track_name = track.trackName or 'Unknown'
    local artist_name = track.artistName or 'Unknown'
    local album_name = track.collectionName or 'Unknown'
    local track_url = track.trackViewUrl or ''
    local artwork_url = track.artworkUrl100 or ''

    -- Format price
    local price = 'N/A'
    if track.trackPrice and track.currency then
        if track.trackPrice < 0 then
            price = 'Not available for individual sale'
        else
            price = string.format('%s %.2f', track.currency, track.trackPrice)
        end
    end

    local output = string.format(
        '<b>%s</b>\nArtist: %s\nAlbum: %s\nPrice: %s',
        tools.escape_html(track_name),
        tools.escape_html(artist_name),
        tools.escape_html(album_name),
        tools.escape_html(price)
    )

    if track_url ~= '' then
        output = output .. string.format('\n<a href="%s">View on iTunes</a>', tools.escape_html(track_url))
    end

    -- Send artwork as photo with caption if available
    if artwork_url ~= '' then
        -- Use higher resolution artwork
        local hires_url = artwork_url:gsub('100x100', '600x600')
        local success = api.send_photo(message.chat.id, hires_url, { caption = output, parse_mode = 'html' })
        if success then
            return success
        end
    end

    -- Fallback to text-only
    return api.send_message(message.chat.id, output, { parse_mode = 'html', link_preview_options = { is_disabled = true } })
end

return plugin
