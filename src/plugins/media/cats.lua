--[[
    mattata v2.0 - Cats Plugin
    Sends a random cat image from TheCatAPI.
]]

local plugin = {}
plugin.name = 'cats'
plugin.category = 'media'
plugin.description = 'Get a random cat image'
plugin.commands = { 'cat', 'cats' }
plugin.help = '/cat - Sends a random cat image.'

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local ltn12 = require('ltn12')

    local response_body = {}
    local res, code = https.request({
        url = 'https://api.thecatapi.com/v1/images/search',
        method = 'GET',
        sink = ltn12.sink.table(response_body),
        headers = {
            ['Accept'] = 'application/json'
        }
    })

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to fetch a cat image. Please try again later.')
    end

    local body = table.concat(response_body)
    local data, _ = json.decode(body)
    if not data or #data == 0 then
        return api.send_message(message.chat.id, 'No cat images found. Please try again later.')
    end

    local image_url = data[1].url
    if not image_url then
        return api.send_message(message.chat.id, 'Failed to parse the cat image response.')
    end

    -- Send as animation if it's a gif, otherwise as photo
    if image_url:lower():match('%.gif$') then
        return api.send_animation(message.chat.id, image_url)
    end
    return api.send_photo(message.chat.id, image_url)
end

return plugin
