--[[
    mattata v2.0 - GitHub Plugin
    Fetches information about a GitHub repository.
]]

local plugin = {}
plugin.name = 'github'
plugin.category = 'utility'
plugin.description = 'View information about a GitHub repository'
plugin.commands = { 'github', 'gh' }
plugin.help = '/gh <owner/repo> - View information about a GitHub repository.'

function plugin.on_message(api, message, ctx)
    local http = require('src.core.http')
    local tools = require('telegram-bot-lua.tools')

    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please specify a repository. Usage: /gh <owner/repo>')
    end

    -- Extract owner/repo from various input formats
    local owner, repo = input:match('^([%w%.%-_]+)/([%w%.%-_]+)$')
    if not owner then
        -- Try extracting from a full GitHub URL
        owner, repo = input:match('github%.com/([%w%.%-_]+)/([%w%.%-_]+)')
    end
    if not owner or not repo then
        return api.send_message(message.chat.id, 'Invalid repository format. Use: /gh owner/repo')
    end

    local api_url = string.format('https://api.github.com/repos/%s/%s', owner, repo)
    local data, code = http.get_json(api_url, {
        ['Accept'] = 'application/vnd.github.v3+json'
    })
    if not data then
        return api.send_message(message.chat.id, 'Repository not found or GitHub API is unavailable.')
    end
    if not data or data.message then
        return api.send_message(message.chat.id, 'Repository not found: ' .. (data and data.message or 'unknown error'))
    end

    local lines = {
        string.format('<b>%s</b>', tools.escape_html(data.full_name or (owner .. '/' .. repo)))
    }

    if data.description and data.description ~= '' then
        table.insert(lines, tools.escape_html(data.description))
    end

    table.insert(lines, '')

    if data.language then
        table.insert(lines, 'Language: <code>' .. tools.escape_html(data.language) .. '</code>')
    end
    table.insert(lines, string.format('Stars: <code>%s</code>', data.stargazers_count or 0))
    table.insert(lines, string.format('Forks: <code>%s</code>', data.forks_count or 0))
    table.insert(lines, string.format('Open issues: <code>%s</code>', data.open_issues_count or 0))

    if data.license and data.license.spdx_id then
        table.insert(lines, 'License: <code>' .. tools.escape_html(data.license.spdx_id) .. '</code>')
    end

    if data.created_at then
        table.insert(lines, 'Created: <code>' .. data.created_at:sub(1, 10) .. '</code>')
    end

    local keyboard = api.inline_keyboard():row(
        api.row():url_button('View on GitHub', data.html_url or ('https://github.com/' .. owner .. '/' .. repo))
    )

    return api.send_message(message.chat.id, table.concat(lines, '\n'), { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
end

return plugin
