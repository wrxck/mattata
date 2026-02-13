--[[
    mattata v2.0 - Search Plugin
    Web search using DuckDuckGo Instant Answers API.
]]

local plugin = {}
plugin.name = 'search'
plugin.category = 'utility'
plugin.description = 'Search the web using DuckDuckGo'
plugin.commands = { 'search', 'ddg', 'google' }
plugin.help = '/search <query> - Search the web using DuckDuckGo Instant Answers.'

local http = require('src.core.http')
local url = require('socket.url')
local tools = require('telegram-bot-lua.tools')

local function search(query)
    local encoded = url.escape(query)
    local request_url = 'https://api.duckduckgo.com/?q=' .. encoded .. '&format=json&no_redirect=1&no_html=1&skip_disambig=1'
    local data, code = http.get_json(request_url)
    if not data then
        return nil, 'Search request failed (HTTP ' .. tostring(code) .. ').'
    end
    return data
end

local function format_results(data, query)
    local lines = {}

    -- Abstract (instant answer)
    if data.AbstractText and data.AbstractText ~= '' then
        table.insert(lines, '<b>' .. tools.escape_html(data.Heading or query) .. '</b>')
        table.insert(lines, '')
        local abstract = data.AbstractText
        if #abstract > 500 then
            abstract = abstract:sub(1, 497) .. '...'
        end
        table.insert(lines, tools.escape_html(abstract))
        if data.AbstractURL and data.AbstractURL ~= '' then
            table.insert(lines, '')
            table.insert(lines, '<a href="' .. tools.escape_html(data.AbstractURL) .. '">Read more</a>')
        end
        return table.concat(lines, '\n')
    end

    -- Answer (calculations, conversions, etc.)
    if data.Answer and data.Answer ~= '' then
        local answer = data.Answer:gsub('<[^>]+>', '') -- strip HTML tags
        table.insert(lines, '<b>Answer:</b> ' .. tools.escape_html(answer))
        return table.concat(lines, '\n')
    end

    -- Definition
    if data.Definition and data.Definition ~= '' then
        table.insert(lines, '<b>Definition:</b>')
        table.insert(lines, tools.escape_html(data.Definition))
        if data.DefinitionSource and data.DefinitionSource ~= '' then
            table.insert(lines, '<i>Source: ' .. tools.escape_html(data.DefinitionSource) .. '</i>')
        end
        return table.concat(lines, '\n')
    end

    -- Related topics
    if data.RelatedTopics and #data.RelatedTopics > 0 then
        table.insert(lines, '<b>Results for:</b> ' .. tools.escape_html(query))
        table.insert(lines, '')
        local count = 0
        for _, topic in ipairs(data.RelatedTopics) do
            if count >= 5 then break end
            if topic.Text and topic.Text ~= '' then
                local text = topic.Text
                if #text > 200 then
                    text = text:sub(1, 197) .. '...'
                end
                if topic.FirstURL and topic.FirstURL ~= '' then
                    table.insert(lines, '<a href="' .. tools.escape_html(topic.FirstURL) .. '">' .. tools.escape_html(text) .. '</a>')
                else
                    table.insert(lines, tools.escape_html(text))
                end
                count = count + 1
            end
        end
        if count > 0 then
            return table.concat(lines, '\n')
        end
    end

    -- Redirect (bang or direct answer)
    if data.Redirect and data.Redirect ~= '' then
        return '<b>Redirect:</b> <a href="' .. tools.escape_html(data.Redirect) .. '">' .. tools.escape_html(query) .. '</a>'
    end

    return nil
end

function plugin.on_message(api, message, ctx)
    local input = message.args
    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Please provide a search query.\nUsage: <code>/search your query here</code>',
            { parse_mode = 'html' }
        )
    end

    local data, err = search(input)
    if not data then
        return api.send_message(message.chat.id, err)
    end

    local output = format_results(data, input)
    if not output then
        local ddg_url = 'https://duckduckgo.com/?q=' .. url.escape(input)
        return api.send_message(
            message.chat.id,
            'No instant answers found. <a href="' .. tools.escape_html(ddg_url) .. '">Search on DuckDuckGo</a>',
            { parse_mode = 'html', link_preview_options = { is_disabled = true } }
        )
    end

    return api.send_message(message.chat.id, output, { parse_mode = 'html', link_preview_options = { is_disabled = true } })
end

return plugin
