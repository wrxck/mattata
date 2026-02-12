--[[
    mattata v2.0 - YouTube Plugin
    Searches YouTube using the Data API v3 and returns the top result.
]]

local plugin = {}
plugin.name = 'youtube'
plugin.category = 'media'
plugin.description = 'Search YouTube for videos'
plugin.commands = { 'youtube', 'yt' }
plugin.help = '/youtube <query> - Search YouTube and return the top result with title, channel, and views.'

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')
    local ltn12 = require('ltn12')

    local api_key = ctx.config.get('YOUTUBE_API_KEY')
    if not api_key then
        return api.send_message(message.chat.id, 'The YouTube API key has not been configured.')
    end

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Please specify a search query, e.g. <code>/yt never gonna give you up</code>.', 'html')
    end

    -- Step 1: Search for videos
    local query = url.escape(message.args)
    local search_url = string.format(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=%s&key=%s',
        query, api_key
    )

    local response_body = {}
    local res, code = https.request({
        url = search_url,
        method = 'GET',
        sink = ltn12.sink.table(response_body),
        headers = {
            ['Accept'] = 'application/json'
        }
    })

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to search YouTube. Please try again later.')
    end

    local body = table.concat(response_body)
    local data, _ = json.decode(body)
    if not data or not data.items or #data.items == 0 then
        return api.send_message(message.chat.id, 'No results found for that query.')
    end

    local item = data.items[1]
    local video_id = item.id and item.id.videoId
    local title = item.snippet and item.snippet.title or 'Unknown'
    local channel = item.snippet and item.snippet.channelTitle or 'Unknown'

    if not video_id then
        return api.send_message(message.chat.id, 'Failed to parse the YouTube search results.')
    end

    -- Step 2: Fetch video statistics
    local stats_url = string.format(
        'https://www.googleapis.com/youtube/v3/videos?part=statistics&id=%s&key=%s',
        video_id, api_key
    )

    local stats_body = {}
    local stats_res, stats_code = https.request({
        url = stats_url,
        method = 'GET',
        sink = ltn12.sink.table(stats_body),
        headers = {
            ['Accept'] = 'application/json'
        }
    })

    local views = 'N/A'
    if stats_res and stats_code == 200 then
        local stats_data = json.decode(table.concat(stats_body))
        if stats_data and stats_data.items and #stats_data.items > 0 then
            local stats = stats_data.items[1].statistics
            if stats and stats.viewCount then
                -- Format view count with commas
                views = tostring(stats.viewCount):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
            end
        end
    end

    local video_url = 'https://youtu.be/' .. video_id
    local output = string.format(
        '<a href="%s">%s</a>\nChannel: %s\nViews: %s',
        tools.escape_html(video_url),
        tools.escape_html(title),
        tools.escape_html(channel),
        views
    )

    return api.send_message(message.chat.id, output, 'html', true)
end

return plugin
