--[[
    mattata v2.0 - Calculator Plugin
    Evaluates mathematical expressions using the mathjs.org API.
]]

local plugin = {}
plugin.name = 'calc'
plugin.category = 'utility'
plugin.description = 'Evaluate mathematical expressions'
plugin.commands = { 'calc', 'calculate', 'calculator' }
plugin.help = '/calc <expression> - Evaluate a mathematical expression.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local url = require('socket.url')
    local tools = require('telegram-bot-lua.tools')

    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please provide an expression to evaluate. Example: /calc 2+2*5')
    end

    local encoded = url.escape(input)
    local api_url = 'https://api.mathjs.org/v4/?expr=' .. encoded
    local body, status = http.get(api_url)
    if not body or status ~= 200 then
        return api.send_message(message.chat.id, 'Failed to evaluate that expression. Please check the syntax and try again.')
    end

    -- mathjs returns the result as plain text
    local result = body:match('^%s*(.-)%s*$')
    if not result or result == '' then
        return api.send_message(message.chat.id, 'No result returned for that expression.')
    end

    return api.send_message(
        message.chat.id,
        string.format('<b>Expression:</b> <code>%s</code>\n<b>Result:</b> <code>%s</code>', tools.escape_html(input), tools.escape_html(result)),
        { parse_mode = 'html' }
    )
end

return plugin
