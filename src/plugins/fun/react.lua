--[[
    mattata v2.1 - React Plugin
    Set message reactions via the Bot API.
]]

local plugin = {}
plugin.name = 'react'
plugin.category = 'fun'
plugin.description = 'React to messages with emoji'
plugin.commands = { 'react' }
plugin.help = '/react <emoji> - Reply to a message to react with the specified emoji.'

local json = require('dkjson')

function plugin.on_message(api, message, ctx)
    if not message.reply then
        return api.send_message(message.chat.id, 'Reply to a message with /react <emoji> to add a reaction.')
    end

    if not message.args or message.args == '' then
        return api.send_message(message.chat.id, 'Usage: /react <emoji>\n\nExample: /react \xF0\x9F\x91\x8D')
    end

    local emoji = message.args:match('^%s*(.-)%s*$')
    local reaction = json.encode({
        { type = 'emoji', emoji = emoji }
    })

    local result = api.set_message_reaction(message.chat.id, message.reply.message_id, { reaction = reaction })
    if result then
        -- Delete the command message to keep chat clean
        api.delete_message(message.chat.id, message.message_id)
    else
        return api.send_message(message.chat.id, 'Failed to set reaction. The emoji may not be supported.')
    end
end

return plugin
