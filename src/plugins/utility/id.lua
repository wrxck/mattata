--[[
    mattata v2.0 - ID Plugin
    Returns user/chat ID and information.
]]

local plugin = {}
plugin.name = 'id'
plugin.category = 'utility'
plugin.description = 'Get user or chat ID and info'
plugin.commands = { 'id', 'user', 'whoami' }
plugin.help = '/id [user] - Returns ID and info for the given user, or yourself if no argument is given.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local target = message.from
    local input = message.args

    -- If replying to someone, use their info
    if message.reply and message.reply.from then
        target = message.reply.from
    elseif input and input ~= '' then
        -- Try to resolve username or ID
        local resolved = input:match('^@?(.+)$')
        local user_id = tonumber(resolved) or ctx.redis.get('username:' .. resolved:lower())
        if user_id then
            local result = api.get_chat(user_id)
            if result and result.result then
                target = result.result
            end
        end
    end

    local lines = {}
    table.insert(lines, '<b>User Information</b>')
    table.insert(lines, 'ID: <code>' .. target.id .. '</code>')
    table.insert(lines, 'Name: ' .. tools.escape_html(target.first_name or ''))
    if target.last_name then
        table.insert(lines, 'Last name: ' .. tools.escape_html(target.last_name))
    end
    if target.username then
        table.insert(lines, 'Username: @' .. target.username)
    end
    if target.language_code then
        table.insert(lines, 'Language: <code>' .. target.language_code .. '</code>')
    end

    -- If in a group, also show chat info
    if ctx.is_group then
        table.insert(lines, '')
        table.insert(lines, '<b>Chat Information</b>')
        table.insert(lines, 'ID: <code>' .. message.chat.id .. '</code>')
        table.insert(lines, 'Title: ' .. tools.escape_html(message.chat.title or ''))
        table.insert(lines, 'Type: ' .. (message.chat.type or 'unknown'))
        if message.chat.username then
            table.insert(lines, 'Username: @' .. message.chat.username)
        end
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
