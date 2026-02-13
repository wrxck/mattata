--[[
    mattata v2.0 - GIF Plugin
    Searches for GIFs using the Tenor API and sends them as animations.
]]

local plugin = {}
plugin.name = 'gif'
plugin.category = 'media'
plugin.description = 'Search for GIFs using Tenor'
plugin.commands = { 'gif', 'tenor' }
plugin.help = '/gif <query> - Search for a GIF and send it.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local url = require('socket.url')

    local tenor_key = ctx.config.get('TENOR_API_KEY')
    if not tenor_key or tenor_key == '' then
        return api.send_message(message.chat.id, 'The Tenor API key is not configured. Please set <code>TENOR_API_KEY</code> in the bot configuration.', 'html')
    end

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Please specify a search query, e.g. <code>/gif funny cats</code>.', { parse_mode = 'html' })
    end

    local query = url.escape(message.args)
    local api_url = string.format(
        'https://tenor.googleapis.com/v2/search?q=%s&key=%s&limit=1&media_filter=gif',
        query, tenor_key
    )

    local data, _ = http.get_json(api_url)

    if not data then
        return api.send_message(message.chat.id, 'Failed to search Tenor. Please try again later.')
    end
    if not data or not data.results or #data.results == 0 then
        return api.send_message(message.chat.id, 'No GIFs found for that query.')
    end

    local result = data.results[1]
    local gif_url = result.media_formats
        and result.media_formats.gif
        and result.media_formats.gif.url

    if not gif_url then
        return api.send_message(message.chat.id, 'Failed to retrieve the GIF URL.')
    end

    return api.send_animation(message.chat.id, gif_url)
end

return plugin
