--[[
    mattata v2.0 - Inline Query Plugin
    Multi-purpose inline query handler for @botname queries.
    Supports: wiki, ud, calc, translate
]]

local plugin = {}
plugin.name = 'inline'
plugin.category = 'utility'
plugin.description = 'Handle inline queries for Wikipedia, Urban Dictionary, calculator, and translation'
plugin.commands = {}

local http = require('src.core.http')
local json = require('dkjson')
local url = require('socket.url')
local tools = require('telegram-bot-lua.tools')
local logger = require('src.core.logger')

local LIBRE_TRANSLATE_URL = 'https://libretranslate.com'

--- Build an InlineQueryResultArticle table.
local function article(id, title, description, message_text, parse_mode)
    return {
        type = 'article',
        id = tostring(id),
        title = title,
        description = description or '',
        input_message_content = {
            message_text = message_text,
            parse_mode = parse_mode or 'html'
        }
    }
end

--- Strip HTML tags from a string (used for Wikipedia snippets).
local function strip_html(s)
    if not s then return '' end
    return s:gsub('<[^>]+>', '')
end

--- Truncate a string to max_len characters, appending '...' if truncated.
local function truncate(s, max_len)
    if not s then return '' end
    if #s <= max_len then return s end
    return s:sub(1, max_len) .. '...'
end

--- Wikipedia inline search: returns up to 5 article results.
local function handle_wiki(query)
    local encoded = url.escape(query)
    local api_url = string.format(
        'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&format=json&utf8=1&srlimit=5',
        encoded
    )
    local data, _ = http.get_json(api_url)
    if not data or not data.query or not data.query.search or #data.query.search == 0 then
        return { article(1, 'No results', 'No Wikipedia articles found for "' .. query .. '".',
            'No Wikipedia articles found for "' .. tools.escape_html(query) .. '".') }
    end
    local results = {}
    for i, entry in ipairs(data.query.search) do
        local title = entry.title or 'Untitled'
        local snippet = strip_html(entry.snippet or '')
        snippet = truncate(snippet, 200)
        local page_url = 'https://en.wikipedia.org/wiki/' .. title:gsub(' ', '_')
        local message_text = string.format(
            '<b>%s</b>\n\n%s\n\n%s',
            tools.escape_html(title),
            tools.escape_html(snippet),
            tools.escape_html(page_url)
        )
        results[#results + 1] = article(i, title, snippet, message_text)
    end
    return results
end

--- Urban Dictionary inline lookup: returns up to 3 article results.
local function handle_ud(query)
    local encoded = url.escape(query)
    local api_url = 'https://api.urbandictionary.com/v0/define?term=' .. encoded
    local data, _ = http.get_json(api_url)
    if not data or not data.list or #data.list == 0 then
        return { article(1, 'No results', 'No definitions found for "' .. query .. '".',
            'No Urban Dictionary definitions found for "' .. tools.escape_html(query) .. '".') }
    end
    local results = {}
    local limit = math.min(3, #data.list)
    for i = 1, limit do
        local entry = data.list[i]
        local word = entry.word or query
        local definition = (entry.definition or ''):gsub('%[', ''):gsub('%]', '')
        local example = (entry.example or ''):gsub('%[', ''):gsub('%]', '')
        definition = truncate(definition, 300)
        example = truncate(example, 200)
        local desc = truncate(definition, 100)
        local lines = {
            string.format('<b>%s</b>', tools.escape_html(word)),
            '',
            string.format('<i>%s</i>', tools.escape_html(definition))
        }
        if example ~= '' then
            table.insert(lines, '')
            table.insert(lines, 'Example: ' .. tools.escape_html(example))
        end
        results[#results + 1] = article(i, word, desc, table.concat(lines, '\n'))
    end
    return results
end

--- Calculator inline handler: returns a single article result.
local function handle_calc(expression)
    local encoded = url.escape(expression)
    local api_url = 'https://api.mathjs.org/v4/?expr=' .. encoded
    local body, status = http.get(api_url)
    if not body or status ~= 200 then
        return { article(1, 'Calculation error', 'Could not evaluate: ' .. expression,
            'Failed to evaluate expression: ' .. tools.escape_html(expression)) }
    end
    local result = body:match('^%s*(.-)%s*$')
    if not result or result == '' then
        return { article(1, 'No result', 'No result for: ' .. expression,
            'No result returned for: ' .. tools.escape_html(expression)) }
    end
    local message_text = string.format(
        '<b>Expression:</b> <code>%s</code>\n<b>Result:</b> <code>%s</code>',
        tools.escape_html(expression),
        tools.escape_html(result)
    )
    return { article(1, result, expression .. ' = ' .. result, message_text) }
end

--- Translate inline handler: auto-detect source language, translate to English.
local function handle_translate(text)
    local request_body = json.encode({
        q = text,
        source = 'auto',
        target = 'en',
        format = 'text'
    })
    local body, code = http.post(LIBRE_TRANSLATE_URL .. '/translate', request_body, 'application/json')
    if code ~= 200 or not body then
        return { article(1, 'Translation failed', 'Could not translate the given text.',
            'Translation failed. The service may be temporarily unavailable.') }
    end
    local data = json.decode(body)
    if not data or not data.translatedText then
        return { article(1, 'Translation failed', 'Could not parse translation response.',
            'Translation failed. Could not parse the response from the translation service.') }
    end
    local translated = data.translatedText
    local source_lang = data.detectedLanguage and data.detectedLanguage.language or '??'
    local message_text = string.format(
        '<b>Translation</b> [%s -> EN]\n\n%s',
        tools.escape_html(source_lang:upper()),
        tools.escape_html(translated)
    )
    local _ = truncate(translated, 100)
    return { article(1, translated, source_lang:upper() .. ' -> EN', message_text) }
end

--- Build the help result shown when no valid type prefix is given.
local function help_results()
    local help_text = table.concat({
        '<b>Inline Query Help</b>',
        '',
        'Type <code>@botname &lt;type&gt; &lt;query&gt;</code> in any chat.',
        '',
        '<b>Supported types:</b>',
        '  <code>wiki &lt;query&gt;</code> - Search Wikipedia',
        '  <code>ud &lt;query&gt;</code> - Urban Dictionary lookup',
        '  <code>calc &lt;expression&gt;</code> - Calculator',
        '  <code>translate &lt;text&gt;</code> - Translate to English',
        '',
        'Examples:',
        '  <code>@botname wiki Lua programming</code>',
        '  <code>@botname ud yeet</code>',
        '  <code>@botname calc 2+2*5</code>',
        '  <code>@botname translate Bonjour le monde</code>'
    }, '\n')
    return { article(1, 'Inline Query Help', 'Type @botname wiki/ud/calc/translate <query>', help_text) }
end

--- Dispatch table for query types.
local handlers = {
    wiki = handle_wiki,
    ud = handle_ud,
    calc = handle_calc,
    translate = handle_translate
}

function plugin.on_inline_query(api, inline_query, ctx)
    local ok, err = pcall(function()
        local query = inline_query.query or ''
        query = query:match('^%s*(.-)%s*$')  -- trim whitespace

        -- Show help if query is too short
        if not query or #query < 2 then
            local results = help_results()
            return api.answer_inline_query(inline_query.id, results, { cache_time = 300 })
        end

        -- Parse the type prefix and remaining query
        local query_type, query_text = query:match('^(%S+)%s+(.+)$')

        if not query_type or not query_text then
            local results = help_results()
            return api.answer_inline_query(inline_query.id, results, { cache_time = 300 })
        end

        query_type = query_type:lower()
        query_text = query_text:match('^%s*(.-)%s*$')  -- trim

        local handler = handlers[query_type]
        if not handler then
            local results = help_results()
            return api.answer_inline_query(inline_query.id, results, { cache_time = 300 })
        end

        if not query_text or query_text == '' then
            local results = help_results()
            return api.answer_inline_query(inline_query.id, results, { cache_time = 300 })
        end

        local results = handler(query_text)
        api.answer_inline_query(inline_query.id, results, { cache_time = 300 })
    end)

    if not ok then
        -- Silently fail on errors — don't crash the bot for inline queries
        logger.warn('Inline query handler error: %s', tostring(err))
    end
end

return plugin
