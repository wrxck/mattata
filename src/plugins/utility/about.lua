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
    local config = require('src.core.config')
    local owner_id = config.get_list('BOT_ADMINS')[1] or '221714512'
    local github_url = config.get('GITHUB_URL', 'https://github.com/wrxck/mattata')
    local output = string.format(
        'Created by <a href="tg://user?id=%s">Matt</a>. Powered by <code>mattata v%s</code>. Source code available <a href="%s">on GitHub</a>.',
        owner_id, config.VERSION, github_url
    )
    return api.send_message(message.chat.id, output, 'html')
end

return plugin
