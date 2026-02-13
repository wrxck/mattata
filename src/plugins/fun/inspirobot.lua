--[[
    mattata v2.0 - InspiroBot Plugin
    Fetches a random AI-generated inspirational image from inspirobot.me.
]]

local plugin = {}
plugin.name = 'inspirobot'
plugin.category = 'fun'
plugin.description = 'Get a random AI-generated inspirational image'
plugin.commands = { 'inspirobot', 'ib' }
plugin.help = '/inspirobot - Get a random AI-generated inspirational poster from InspiroBot.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')

    local body, code = http.get('https://inspirobot.me/api?generate=true')

    if code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to fetch an inspirational image. Try again later.')
    end

    local image_url = body:gsub('%s+', '')
    if not image_url or image_url == '' or not image_url:match('^https?://') then
        return api.send_message(message.chat.id, 'Received an invalid response from InspiroBot. Try again later.')
    end

    return api.send_photo(message.chat.id, image_url, { reply_parameters = { message_id = message.message_id } })
end

return plugin
