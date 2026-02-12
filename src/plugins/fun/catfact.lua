--[[
    mattata v2.0 - Cat Fact Plugin
    Fetches a real cat fact from the catfact.ninja API.
]]

local plugin = {}
plugin.name = 'catfact'
plugin.category = 'fun'
plugin.description = 'Get a random real cat fact'
plugin.commands = { 'catfact', 'cfact' }
plugin.help = '/catfact - Get a random cat fact from catfact.ninja.'

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local ltn12 = require('ltn12')

    local response_body = {}
    local res, code = https.request({
        url = 'https://catfact.ninja/fact',
        method = 'GET',
        headers = {
            ['Accept'] = 'application/json'
        },
        sink = ltn12.sink.table(response_body)
    })

    if not res or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to fetch a cat fact. Try again later.')
    end

    local body = table.concat(response_body)
    local data, _, err = json.decode(body)
    if not data or not data.fact then
        return api.send_message(message.chat.id, 'Failed to parse cat fact response. Try again later.')
    end

    local output = string.format('\xF0\x9F\x90\xB1 <b>Cat Fact:</b> %s', data.fact)
    return api.send_message(message.chat.id, output, 'html')
end

return plugin
