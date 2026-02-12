--[[
    mattata v2.0 - About Plugin
]]

local plugin = {}
plugin.name = 'about'
plugin.category = 'utility'
plugin.description = 'View information about the bot'
plugin.commands = { 'about' }
plugin.help = '/about - View information about the bot.'
plugin.permanent = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local config = require('src.core.config')
    local output = string.format(
        'Created by <a href="tg://user?id=221714512">Matt</a>. Powered by <code>mattata v%s</code>. Source code available <a href="https://github.com/wrxck/mattata">on GitHub</a>.',
        config.VERSION
    )
    return api.send_message(message.chat.id, output, 'html')
end

return plugin
