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
    local http = require('src.core.http')

    local data, code = http.get_json('https://catfact.ninja/fact')

    if not data then
        return api.send_message(message.chat.id, 'Failed to fetch a cat fact. Try again later.')
    end
    if not data or not data.fact then
        return api.send_message(message.chat.id, 'Failed to parse cat fact response. Try again later.')
    end

    local output = string.format('\xF0\x9F\x90\xB1 <b>Cat Fact:</b> %s', data.fact)
    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
