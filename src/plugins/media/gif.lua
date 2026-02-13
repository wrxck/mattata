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

local TENOR_KEY = 'AIzaSyAyimkuYQYF_FXVALexPuGQctUWRURdCYQ'

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local url = require('socket.url')
    local ltn12 = require('ltn12')

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Please specify a search query, e.g. <code>/gif funny cats</code>.', { parse_mode = 'html' })
    end

    local query = url.escape(message.args)
    local api_url = string.format(
        'https://tenor.googleapis.com/v2/search?q=%s&key=%s&limit=1&media_filter=gif',
        query, TENOR_KEY
    )

    local response_body = {}
    local res, code = https.request({
        url = api_url,
        method = 'GET',
        sink = ltn12.sink.table(response_body),
        headers = {
            ['Accept'] = 'application/json'
        }
    })

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to search Tenor. Please try again later.')
    end

    local body = table.concat(response_body)
    local data, _ = json.decode(body)
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
