--[[
    mattata v2.0 - Slap Plugin
    Slap users with random messages using templates.
]]

local plugin = {}
plugin.name = 'slap'
plugin.category = 'fun'
plugin.description = 'Slap a user with a random object'
plugin.commands = { 'slap' }
plugin.help = '/slap [user] - Slap a user with a random message. Use in reply to target the replied user.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local slaps = require('src.data.slaps')

    local sender_name = message.from.first_name or 'Unknown'
    local target_name

    if message.reply and message.reply.from then
        target_name = message.reply.from.first_name or 'Unknown'
    elseif message.args and message.args ~= '' then
        target_name = message.args
    else
        -- Slap yourself if no target
        target_name = sender_name
        sender_name = api.info.first_name
    end

    math.randomseed(os.time() + os.clock() * 1000)
    local template = slaps[math.random(#slaps)]
    local output = template:gsub('{ME}', tools.escape_html(sender_name)):gsub('{THEM}', tools.escape_html(target_name))

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
