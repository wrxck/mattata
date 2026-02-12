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
    local https = require('ssl.https')
    local ltn12 = require('ltn12')

    local response_body = {}
    local res, code = https.request({
        url = 'https://inspirobot.me/api?generate=true',
        method = 'GET',
        sink = ltn12.sink.table(response_body)
    })

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to fetch an inspirational image. Try again later.')
    end

    local image_url = table.concat(response_body):gsub('%s+', '')
    if not image_url or image_url == '' or not image_url:match('^https?://') then
        return api.send_message(message.chat.id, 'Received an invalid response from InspiroBot. Try again later.')
    end

    return api.send_photo(message.chat.id, image_url, nil, false, message.message_id)
end

return plugin
