--[[
    mattata v2.0 - QR Code Plugin
    Generates QR codes from text or URLs using the goqr.me API.
]]

local plugin = {}
plugin.name = 'qr'
plugin.category = 'media'
plugin.description = 'Generate a QR code from text or a URL'
plugin.commands = { 'qr', 'qrcode' }
plugin.help = '/qr <text or URL> - Generate a QR code. Also works as a reply to a message.'

local MAX_INPUT = 2000

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
            'Please provide text or a URL to encode.\nUsage: <code>/qr hello world</code>\nOr reply to a message with <code>/qr</code>',
            { parse_mode = 'html' }
        )
    end

    if #input > MAX_INPUT then
        return api.send_message(
            message.chat.id,
            string.format('Input is too long (%d characters). Maximum is %d.', #input, MAX_INPUT)
        )
    end

    local qr_url = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=' .. url_encode(input)
    local result = api.send_photo(message.chat.id, qr_url)
    if not result or not result.result then
        return api.send_message(message.chat.id, 'Failed to generate QR code. Please try again.')
    end
    return result
end

return plugin
