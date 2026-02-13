--[[
    mattata v2.0 - Paste Plugin
    Pastes text to dpaste.org and returns the URL.
]]

local plugin = {}
plugin.name = 'paste'
plugin.category = 'utility'
plugin.description = 'Paste text to dpaste.org and get a shareable link'
plugin.commands = { 'paste', 'p' }
plugin.help = '/paste <text> - Paste text to dpaste.org. Also works as a reply to a message.'

local http = require('src.core.http')

local MAX_INPUT = 50000

local function url_encode(str)
    return str:gsub('([^%w%-%.%_%~])', function(c)
        return string.format('%%%02X', string.byte(c))
    end)
end

function plugin.on_message(api, message, ctx)
    local input = message.args

    -- If no args, try to use the replied message text
    if (not input or input == '') and message.reply then
        input = message.reply.text or message.reply.caption
    end

    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Please provide text to paste.\nUsage: <code>/paste hello world</code>\nOr reply to a message with <code>/paste</code>',
            { parse_mode = 'html' }
        )
    end

    if #input > MAX_INPUT then
        return api.send_message(
            message.chat.id,
            string.format('Input is too long (%d characters). Maximum is %d.', #input, MAX_INPUT)
        )
    end

    local post_body = 'content=' .. url_encode(input) .. '&format=url'
    -- Add syntax=text for code or long text
    if #input > 200 then
        post_body = post_body .. '&syntax=text'
    end

    local body, code = http.post('https://dpaste.org/api/', post_body, 'application/x-www-form-urlencoded')

    if not body or body == '' or code ~= 200 then
        return api.send_message(message.chat.id, 'Failed to create paste. Please try again later.')
    end

    -- dpaste returns the URL with a trailing newline
    local paste_url = body:match('^%s*(.-)%s*$')
    if not paste_url or paste_url == '' then
        return api.send_message(message.chat.id, 'Failed to parse the paste URL from the response.')
    end

    return api.send_message(
        message.chat.id,
        string.format('<a href="%s">Pasted!</a> Expires in 7 days.', paste_url),
        { parse_mode = 'html' }
    )
end

return plugin
