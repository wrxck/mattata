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
        'html'
    )
end

return plugin
