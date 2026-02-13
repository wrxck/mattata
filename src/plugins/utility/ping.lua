--[[
    mattata v2.0 - Ping Plugin
]]

local plugin = {}
plugin.name = 'ping'
plugin.category = 'utility'
plugin.description = 'Check bot responsiveness'
plugin.commands = { 'ping', 'pong' }
plugin.help = '/ping - PONG!'

function plugin.on_message(api, message, ctx)
    local socket = require('socket')
    local latency = math.floor((socket.gettime() - (message.date or socket.gettime())) * 1000)
    if message.command == 'pong' then
        return api.send_message(message.chat.id, 'You really have to go the extra mile, don\'t you?')
    end
    return api.send_message(message.chat.id, string.format('Pong! <code>%dms</code>', latency), { parse_mode = 'html' })
end

return plugin
