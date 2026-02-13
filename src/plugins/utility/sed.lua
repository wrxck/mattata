--[[
    mattata v2.0 - Sed Plugin
    Regex-style substitution on replied-to messages using Lua patterns.
]]

local plugin = {}
plugin.name = 'sed'
plugin.category = 'utility'
plugin.description = 'Regex-style find and replace on messages'
plugin.commands = {}
plugin.help = 's/pattern/replacement/ - Reply to a message to perform a find-and-replace using Lua patterns.'

function plugin.on_new_message(api, message, ctx)
    if not message.text then return end
    if not message.reply then return end
    if not message.reply.text or message.reply.text == '' then return end

    -- Match s/pattern/replacement/ or s/pattern/replacement (no trailing slash)
    -- Support escaped forward slashes within the pattern/replacement
    local pattern, replacement, flags = message.text:match('^s/(.-[^\\])/(.-[^\\]?)/([gi]*)$')
    if not pattern then
        pattern, replacement = message.text:match('^s/(.-[^\\])/(.-[^\\]?)/?$')
        flags = ''
    end
    -- Handle edge case: empty replacement
    if not pattern then
        pattern = message.text:match('^s/(.-[^\\])//[gi]*$')
        if pattern then replacement = '' end
    end
    if not pattern then
        pattern = message.text:match('^s/(.-[^\\])/$')
        if pattern then replacement = '' end
    end
    if not pattern or not replacement then return end

    -- Unescape forward slashes
    pattern = pattern:gsub('\\/', '/')
    replacement = replacement:gsub('\\/', '/')

    -- Validate the Lua pattern
    local ok, err = pcall(string.find, '', pattern)
    if not ok then
        return api.send_message(message.chat.id, 'Invalid pattern: ' .. tostring(err))
    end

    -- Reject patterns that could cause catastrophic backtracking
    if #pattern > 128 then
        return api.send_message(message.chat.id, 'Pattern too long (max 128 characters).')
    end
    local wq_count = 0
    do
        local i = 1
        while i <= #pattern do
            if pattern:sub(i, i) == '%' then
                i = i + 2
            elseif pattern:sub(i, i) == '.' and i < #pattern then
                local nc = pattern:sub(i + 1, i + 1)
                if nc == '+' or nc == '*' or nc == '-' then wq_count = wq_count + 1 end
                i = i + 1
            else
                i = i + 1
            end
        end
    end
    if wq_count > 3 then
        return api.send_message(message.chat.id, 'Pattern too complex (too many wildcard repetitions).')
    end

    local original = message.reply.text
    local result
    if flags and flags:find('g') then
        result = original:gsub(pattern, replacement)
    else
        result = original:gsub(pattern, replacement, 1)
    end

    if result == original then
        return api.send_message(message.chat.id, 'No matches found for that pattern.')
    end

    local tools = require('telegram-bot-lua.tools')
    local name = tools.escape_html(message.reply.from and message.reply.from.first_name or 'Unknown')
    return api.send_message(
        message.chat.id,
        string.format('<b>%s</b> meant to say:\n%s', name, tools.escape_html(result)),
        { parse_mode = 'html' }
    )
end

return plugin
