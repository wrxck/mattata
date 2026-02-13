--[[
    mattata v2.0 - XKCD Plugin
    Fetches XKCD comics.
]]

local plugin = {}
plugin.name = 'xkcd'
plugin.category = 'utility'
plugin.description = 'View XKCD comics'
plugin.commands = { 'xkcd' }
plugin.help = '/xkcd [number] - View an XKCD comic. If no number is given, shows the latest.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local tools = require('telegram-bot-lua.tools')

    local input = message.args
    local api_url

    if input and input:match('^%d+$') then
        api_url = string.format('https://xkcd.com/%s/info.0.json', input)
    elseif input and input:lower() == 'random' then
        -- Fetch latest to get the max number, then pick random
        local latest, latest_code = http.get_json('https://xkcd.com/info.0.json')
        if latest and latest.num then
            local random_num = math.random(1, latest.num)
            api_url = string.format('https://xkcd.com/%d/info.0.json', random_num)
        end
        if not api_url then
            return api.send_message(message.chat.id, 'Failed to fetch XKCD. Please try again.')
        end
    else
        api_url = 'https://xkcd.com/info.0.json'
    end

    local data, code = http.get_json(api_url)
    if not data then
        return api.send_message(message.chat.id, 'Comic not found. Please check the number and try again.')
    end
    if not data then
        return api.send_message(message.chat.id, 'Failed to parse XKCD response.')
    end

    local caption = string.format(
        '<b>#%d - %s</b>\n<i>%s</i>',
        data.num or 0,
        tools.escape_html(data.title or 'Untitled'),
        tools.escape_html(data.alt or '')
    )

    -- Send the comic image with caption
    if data.img then
        local keyboard = api.inline_keyboard():row(
            api.row():url_button('View on xkcd.com', string.format('https://xkcd.com/%d/', data.num))
        )
        return api.send_photo(message.chat.id, data.img, { caption = caption, parse_mode = 'html', reply_markup = keyboard })
    end

    return api.send_message(message.chat.id, caption, { parse_mode = 'html' })
end

return plugin
