--[[
    mattata v2.0 - Translate Plugin
    Translates text using LibreTranslate public API.
    Supports auto-detection of source language.
]]

local plugin = {}
plugin.name = 'translate'
plugin.category = 'utility'
plugin.description = 'Translate text between languages'
plugin.commands = { 'translate', 'tl' }
plugin.help = '/translate [lang] <text> - Translate text to the specified language (default: en). Reply to a message to translate it, or provide text directly.'

local https = require('ssl.https')
local json = require('dkjson')
local url = require('socket.url')
local ltn12 = require('ltn12')
local tools = require('telegram-bot-lua.tools')

local BASE_URL = 'https://libretranslate.com'

-- Common language code aliases
local LANG_ALIASES = {
    english = 'en', en = 'en',
    spanish = 'es', es = 'es',
    french = 'fr', fr = 'fr',
    german = 'de', de = 'de',
    italian = 'it', it = 'it',
    portuguese = 'pt', pt = 'pt',
    russian = 'ru', ru = 'ru',
    chinese = 'zh', zh = 'zh',
    japanese = 'ja', ja = 'ja',
    korean = 'ko', ko = 'ko',
    arabic = 'ar', ar = 'ar',
    hindi = 'hi', hi = 'hi',
    dutch = 'nl', nl = 'nl',
    polish = 'pl', pl = 'pl',
    turkish = 'tr', tr = 'tr',
    swedish = 'sv', sv = 'sv',
    czech = 'cs', cs = 'cs',
    romanian = 'ro', ro = 'ro',
    hungarian = 'hu', hu = 'hu',
    ukrainian = 'uk', uk = 'uk',
    indonesian = 'id', id = 'id',
    finnish = 'fi', fi = 'fi',
    hebrew = 'he', he = 'he',
    thai = 'th', th = 'th',
    vietnamese = 'vi', vi = 'vi',
    greek = 'el', el = 'el'
}

local function translate_text(text, target, source)
    source = source or 'auto'
    local request_body = json.encode({
        q = text,
        source = source,
        target = target,
        format = 'text'
    })
    local body = {}
    local _, code = https.request({
        url = BASE_URL .. '/translate',
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = tostring(#request_body)
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(body)
    })
    if code ~= 200 then
        return nil, 'Translation service returned an error (HTTP ' .. tostring(code) .. '). The public instance may be rate-limited; try again shortly.'
    end
    local data = json.decode(table.concat(body))
    if not data then
        return nil, 'Failed to parse translation response.'
    end
    if data.error then
        return nil, 'Translation error: ' .. tostring(data.error)
    end
    return {
        translated = data.translatedText,
        source_lang = data.detectedLanguage and data.detectedLanguage.language or source
    }
end

local function detect_language(text)
    local request_body = json.encode({ q = text })
    local body = {}
    local _, code = https.request({
        url = BASE_URL .. '/detect',
        method = 'POST',
        headers = {
            ['Content-Type'] = 'application/json',
            ['Content-Length'] = tostring(#request_body)
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(body)
    })
    if code ~= 200 then
        return 'auto'
    end
    local data = json.decode(table.concat(body))
    if data and data[1] and data[1].language then
        return data[1].language
    end
    return 'auto'
end

function plugin.on_message(api, message, ctx)
    local input = message.args
    local text_to_translate
    local target_lang = 'en'

    -- If replying to a message, use that text
    if message.reply and message.reply.text and message.reply.text ~= '' then
        text_to_translate = message.reply.text
        -- If args given, treat as target language
        if input and input ~= '' then
            local lang = input:match('^(%S+)')
            if lang then
                lang = lang:lower()
                target_lang = LANG_ALIASES[lang] or lang
            end
        end
    elseif input and input ~= '' then
        -- Parse: /translate [lang] <text>
        local first_word, rest = input:match('^(%S+)%s+(.+)$')
        if first_word then
            local resolved = LANG_ALIASES[first_word:lower()]
            if resolved then
                target_lang = resolved
                text_to_translate = rest
            elseif first_word:match('^%a%a$') or first_word:match('^%a%a%a$') then
                -- Assume it's a language code even if not in our alias table
                target_lang = first_word:lower()
                text_to_translate = rest
            else
                -- No language specified, translate the whole input to English
                text_to_translate = input
            end
        else
            text_to_translate = input
        end
    end

    if not text_to_translate or text_to_translate == '' then
        return api.send_message(
            message.chat.id,
            'Please provide text to translate.\nUsage: <code>/translate [lang] text</code>\nOr reply to a message with <code>/translate [lang]</code>',
            'html'
        )
    end

    local result, err = translate_text(text_to_translate, target_lang)
    if not result then
        return api.send_message(message.chat.id, err)
    end

    local source_label = result.source_lang ~= 'auto' and result.source_lang:upper() or '??'
    local output = string.format(
        '<b>Translation</b> [%s -> %s]\n\n%s',
        tools.escape_html(source_label),
        tools.escape_html(target_lang:upper()),
        tools.escape_html(result.translated)
    )

    return api.send_message(message.chat.id, output, 'html')
end

return plugin
