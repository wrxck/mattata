--[[
    mattata v2.0 - Urban Dictionary Plugin
    Looks up definitions from Urban Dictionary.
]]

local plugin = {}
plugin.name = 'urbandictionary'
plugin.category = 'utility'
plugin.description = 'Look up definitions on Urban Dictionary'
plugin.commands = { 'urbandictionary', 'urban', 'ud' }
plugin.help = '/ud <word> - Look up a word on Urban Dictionary.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')

    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please provide a word or phrase to look up. Usage: /ud <word>')
    end

    local encoded = url.escape(input)
    local api_url = 'https://api.urbandictionary.com/v0/define?term=' .. encoded
    local data, code = http.get_json(api_url)
    if not data then
        return api.send_message(message.chat.id, 'Failed to connect to Urban Dictionary. Please try again later.')
    end
    if not data or not data.list or #data.list == 0 then
        return api.send_message(message.chat.id, 'No definitions found for "' .. tools.escape_html(input) .. '".')
    end

    local entry = data.list[1]
    -- Clean up brackets used for linking on the website
    local definition = (entry.definition or ''):gsub('%[', ''):gsub('%]', '')
    local example = (entry.example or ''):gsub('%[', ''):gsub('%]', '')

    -- Truncate long definitions
    if #definition > 1500 then
        definition = definition:sub(1, 1500) .. '...'
    end

    local lines = {
        string.format('<b>%s</b>', tools.escape_html(entry.word or input)),
        '',
        tools.escape_html(definition)
    }

    if example and example ~= '' then
        if #example > 500 then
            example = example:sub(1, 500) .. '...'
        end
        table.insert(lines, '')
        table.insert(lines, '<i>' .. tools.escape_html(example) .. '</i>')
    end

    if entry.thumbs_up or entry.thumbs_down then
        table.insert(lines, '')
        table.insert(lines, string.format(
            '👍 %d  👎 %d',
            entry.thumbs_up or 0,
            entry.thumbs_down or 0
        ))
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html' })
end

return plugin
