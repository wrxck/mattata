--[[
    mattata v2.0 - Wikipedia Plugin
    Looks up Wikipedia articles using the MediaWiki API.
]]

local plugin = {}
plugin.name = 'wikipedia'
plugin.category = 'utility'
plugin.description = 'Look up Wikipedia articles'
plugin.commands = { 'wikipedia', 'wiki', 'w' }
plugin.help = '/wiki <query> - Search Wikipedia for an article.'

local https = require('ssl.https')
local json = require('dkjson')
local url = require('socket.url')
local ltn12 = require('ltn12')
local tools = require('telegram-bot-lua.tools')

local function search_wikipedia(query, lang)
    lang = lang or 'en'
    local encoded = url.escape(query)
    -- Use the REST API summary endpoint via search
    local search_url = string.format(
        'https://%s.wikipedia.org/api/rest_v1/page/summary/%s?redirect=true',
        lang, encoded
    )
    local body = {}
    local _, code = https.request({
        url = search_url,
        sink = ltn12.sink.table(body),
        headers = {
            ['User-Agent'] = 'mattata-telegram-bot/2.0',
            ['Accept'] = 'application/json'
        }
    })
    -- If direct lookup fails, try the search API
    if code ~= 200 then
        return search_wikipedia_fallback(query, lang)
    end
    local data = json.decode(table.concat(body))
    if not data or data.type == 'not_found' or data.type == 'https://mediawiki.org/wiki/HyperSwitch/errors/not_found' then
        return search_wikipedia_fallback(query, lang)
    end
    return data
end

function search_wikipedia_fallback(query, lang)
    lang = lang or 'en'
    local encoded = url.escape(query)
    local search_url = string.format(
        'https://%s.wikipedia.org/w/api.php?action=opensearch&search=%s&limit=1&format=json',
        lang, encoded
    )
    local body = {}
    local _, code = https.request({
        url = search_url,
        sink = ltn12.sink.table(body),
        headers = {
            ['User-Agent'] = 'mattata-telegram-bot/2.0'
        }
    })
    if code ~= 200 then
        return nil, 'Wikipedia search failed (HTTP ' .. tostring(code) .. ').'
    end
    local data = json.decode(table.concat(body))
    if not data or not data[2] or #data[2] == 0 then
        return nil, 'No Wikipedia articles found for that query.'
    end
    -- Fetch the summary for the first result
    local title = data[2][1]
    local title_encoded = url.escape(title)
    local summary_url = string.format(
        'https://%s.wikipedia.org/api/rest_v1/page/summary/%s?redirect=true',
        lang, title_encoded
    )
    body = {}
    _, code = https.request({
        url = summary_url,
        sink = ltn12.sink.table(body),
        headers = {
            ['User-Agent'] = 'mattata-telegram-bot/2.0',
            ['Accept'] = 'application/json'
        }
    })
    if code ~= 200 then
        return nil, 'Failed to retrieve article summary.'
    end
    local summary = json.decode(table.concat(body))
    if not summary then
        return nil, 'Failed to parse article summary.'
    end
    return summary
end

function plugin.on_message(api, message, ctx)
    local input = message.args
    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Please provide a search term.\nUsage: <code>/wiki search term</code>',
            'html'
        )
    end

    local data, err = search_wikipedia(input)
    if not data then
        return api.send_message(message.chat.id, err or 'No Wikipedia articles found for that query.')
    end

    -- Handle disambiguation pages
    if data.type == 'disambiguation' then
        local output = string.format(
            '<b>%s</b> (disambiguation)\n\n%s\n\n<a href="%s">View on Wikipedia</a>',
            tools.escape_html(data.title or input),
            tools.escape_html(data.extract or 'This is a disambiguation page.'),
            tools.escape_html(data.content_urls and data.content_urls.desktop and data.content_urls.desktop.page or '')
        )
        return api.send_message(message.chat.id, output, 'html', true)
    end

    local title = data.title or input
    local extract = data.extract or data.description or 'No summary available.'
    local page_url = data.content_urls and data.content_urls.desktop and data.content_urls.desktop.page or ''

    -- Truncate long extracts
    if #extract > 800 then
        extract = extract:sub(1, 797) .. '...'
    end

    local lines = {
        '<b>' .. tools.escape_html(title) .. '</b>'
    }

    if data.description and data.description ~= '' and data.description ~= extract then
        table.insert(lines, '<i>' .. tools.escape_html(data.description) .. '</i>')
    end

    table.insert(lines, '')
    table.insert(lines, tools.escape_html(extract))

    if page_url ~= '' then
        table.insert(lines, '')
        table.insert(lines, '<a href="' .. tools.escape_html(page_url) .. '">Read more on Wikipedia</a>')
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html', true)
end

return plugin
