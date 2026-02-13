--[[
    mattata v2.0 - Share Plugin
    Creates a share button for a given URL.
]]

local plugin = {}
plugin.name = 'share'
plugin.category = 'utility'
plugin.description = 'Create a share button for a URL'
plugin.commands = { 'share' }
plugin.help = '/share <url> [text] - Create an inline share button for the given URL.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local url_lib = require('socket.url')

    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please provide a URL to share. Usage: /share <url> [text]')
    end

    -- Extract URL and optional text
    local share_url, text = input:match('^(%S+)%s+(.+)$')
    if not share_url then
        share_url = input:match('^(%S+)$')
        text = share_url
    end

    if not share_url then
        return api.send_message(message.chat.id, 'Invalid URL provided.')
    end

    -- Add https:// if no protocol specified
    if not share_url:match('^https?://') then
        share_url = 'https://' .. share_url
    end

    local share_link = string.format(
        'https://t.me/share/url?url=%s&text=%s',
        url_lib.escape(share_url),
        url_lib.escape(text or share_url)
    )

    local keyboard = api.inline_keyboard():row(
        api.row():url_button('Share', share_link)
    )

    return api.send_message(
        message.chat.id,
        string.format('Press the button below to share <code>%s</code>.', tools.escape_html(share_url)),
        { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard }
    )
end

return plugin
