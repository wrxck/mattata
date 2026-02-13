--[[
    mattata v2.1 - ID Plugin
    Returns user/chat ID and information with modern Telegram fields.
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
    if target.is_bot then
        table.insert(lines, 'Bot: Yes')
    end
    if target.is_premium then
        table.insert(lines, 'Premium: Yes')
    end
    if target.added_to_attachment_menu then
        table.insert(lines, 'Attachment menu: Yes')
    end

    -- Profile photo count
    local photos = api.get_user_profile_photos(target.id, 0, 1)
    if photos and photos.result and photos.result.total_count then
        table.insert(lines, 'Profile photos: ' .. photos.result.total_count)
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
        if message.chat.is_forum then
            table.insert(lines, 'Forum: Yes')
        end
        -- Fetch full chat info for extra details
        local chat_info = api.get_chat(message.chat.id)
        if chat_info and chat_info.result then
            local chat = chat_info.result
            if chat.linked_chat_id then
                table.insert(lines, 'Linked chat: <code>' .. chat.linked_chat_id .. '</code>')
            end
            if chat.has_hidden_members then
                table.insert(lines, 'Hidden members: Yes')
            end
            if chat.has_aggressive_anti_spam_enabled then
                table.insert(lines, 'Aggressive anti-spam: Yes')
            end
        end
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
