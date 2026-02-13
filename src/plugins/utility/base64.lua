--[[
    mattata v2.0 - Base64 Plugin
    Encode and decode base64 strings.
]]

local plugin = {}
plugin.name = 'base64'
plugin.category = 'utility'
plugin.description = 'Encode or decode base64 strings'
plugin.commands = { 'base64', 'b64', 'dbase64', 'db64' }
plugin.help = '/base64 <text> - Encode text to base64.\n/dbase64 <text> - Decode base64 to text.'

local mime = require('mime')

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local input = message.args

    -- Also support replying to a message
    if (not input or input == '') and message.reply and message.reply.text then
        input = message.reply.text
    end

    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please provide text to encode or decode.')
    end

    local is_decode = (message.command == 'dbase64' or message.command == 'db64')

    if is_decode then
        -- Decode base64
        local ok, decoded = pcall(mime.unb64, input)
        if not ok or not decoded then
            return api.send_message(message.chat.id, 'Invalid base64 input. Please check the string and try again.')
        end
        return api.send_message(
            message.chat.id,
            string.format('<b>Decoded:</b>\n<code>%s</code>', tools.escape_html(decoded)),
            { parse_mode = 'html' }
        )
    else
        -- Encode to base64
        local encoded = mime.b64(input)
        if not encoded then
            return api.send_message(message.chat.id, 'Failed to encode that text.')
        end
        return api.send_message(
            message.chat.id,
            string.format('<b>Encoded:</b>\n<code>%s</code>', tools.escape_html(encoded)),
            { parse_mode = 'html' }
        )
    end
end

return plugin
