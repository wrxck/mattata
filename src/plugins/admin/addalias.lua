--[[
    mattata v2.0 - Add Alias Plugin
]]

local plugin = {}
plugin.name = 'addalias'
plugin.category = 'admin'
plugin.description = 'Add a command alias'
plugin.commands = { 'addalias' }
plugin.help = '/addalias <alias> <command> - Creates a command alias. Use /delalias <alias> to remove.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    if not message.args then
        -- List existing aliases
        local aliases = ctx.redis.hgetall('chat:' .. message.chat.id .. ':aliases')
        if not aliases or not next(aliases) then
            return api.send_message(message.chat.id, 'No aliases are set.\nUsage: /addalias <alias> <command>')
        end
        local output = '<b>Command aliases:</b>\n\n'
        for alias, original in pairs(aliases) do
            output = output .. string.format('/<code>%s</code> -> /<code>%s</code>\n',
                tools.escape_html(alias), tools.escape_html(original))
        end
        return api.send_message(message.chat.id, output, { parse_mode = 'html' })
    end

    local alias, command = message.args:lower():match('^(%S+)%s+(%S+)$')
    if not alias or not command then
        return api.send_message(message.chat.id, 'Usage: /addalias <alias> <command>')
    end

    -- Strip leading slashes
    alias = alias:gsub('^[/!#]', '')
    command = command:gsub('^[/!#]', '')

    if alias == command then
        return api.send_message(message.chat.id, 'The alias can\'t be the same as the command.')
    end

    ctx.redis.hset('chat:' .. message.chat.id .. ':aliases', alias, command)

    api.send_message(message.chat.id, string.format(
        'Alias created: /<code>%s</code> -> /<code>%s</code>',
        tools.escape_html(alias), tools.escape_html(command)
    ), { parse_mode = 'html' })
end

return plugin
