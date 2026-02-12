--[[
    mattata v2.0 - Internationalisation Module
    Manages language files and provides translation lookups.
]]

local i18n = {}

local config = require('src.core.config')
local logger = require('src.core.logger')

local languages = {}
local default_lang = 'en_gb'

-- Load all available language files from src/languages/
function i18n.init()
    local lang_registry = require('src.languages.init')
    for code, path in pairs(lang_registry) do
        local ok, lang = pcall(require, path)
        if ok and type(lang) == 'table' then
            languages[code] = lang
            logger.debug('Loaded language: %s', code)
        else
            logger.warn('Failed to load language %s: %s', code, tostring(lang))
        end
    end
    logger.info('Loaded %d language(s)', i18n.count())
end

-- Get a language table by code
function i18n.get(code)
    code = code or default_lang
    return languages[code] or languages[default_lang]
end

-- Check if a language exists
function i18n.exists(code)
    return languages[code] ~= nil
end

-- Get all available language codes
function i18n.available()
    local codes = {}
    for code in pairs(languages) do
        table.insert(codes, code)
    end
    table.sort(codes)
    return codes
end

-- Count loaded languages
function i18n.count()
    local count = 0
    for _ in pairs(languages) do
        count = count + 1
    end
    return count
end

-- Translate a key with optional interpolation
-- Usage: i18n.t(lang, 'errors', 'connection') or i18n.t(lang, 'ban', 'success', {name = 'John'})
function i18n.t(lang_table, ...)
    if type(lang_table) == 'string' then
        lang_table = i18n.get(lang_table)
    end
    if not lang_table then
        lang_table = languages[default_lang]
    end
    local args = { ... }
    local value = lang_table
    local interpolation = nil
    for i, key in ipairs(args) do
        if type(key) == 'table' then
            interpolation = key
            break
        end
        if type(value) == 'table' then
            value = value[key]
        else
            return nil
        end
    end
    if type(value) ~= 'string' then
        return nil
    end
    if interpolation then
        for k, v in pairs(interpolation) do
            value = value:gsub('{' .. k .. '}', tostring(v))
        end
    end
    return value
end

return i18n
