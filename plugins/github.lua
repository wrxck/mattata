--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local github = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function github:init()
    github.commands = mattata.commands(self.info.username):command('github'):command('gh').table
    github.help = '/github <username> <repository> - Returns information about the specified GitHub repository. Alias: /gh.'
end

function github:on_new_message(message, _, language)
    if message.text and message.text:match('github%.com/([%w%-_]+)/([%w%-_]+)') and not message.is_edited then
        local user, repo = message.text:match('github.com/([%w%-_]+)/([%w%-_]+)')
        message.text = '/github@' .. self.info.username:lower() .. ' ' .. user .. ' ' .. repo
        message.date = os.time()
        message.is_natural_language = true
        return github.on_message(_, message, _, language)
    end
    return
end

function github.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, github.help)
    end
    input = input:gsub('%s', '/')
    local jstr, res = https.request('https://api.github.com/repos/' .. input)
    if res ~= 200 and not message.is_natural_language then
        return mattata.send_reply(message, language.errors.connection)
    elseif res ~= 200 then
        return
    end
    local jdat = json.decode(jstr)
    if not jdat.id and not message.is_natural_language then
        return mattata.send_reply(message, language.errors.results)
    elseif not jdat.id then
        return
    end
    local title = '<a href="' .. jdat.html_url .. '">' .. mattata.escape_html(jdat.full_name) .. '</a>'
    if jdat.language then
        title = title .. ' <b>|</b> ' .. jdat.language
    end
    local description = jdat.description and '\n<pre>' .. mattata.escape_html(jdat.description) .. '</pre>\n' or '\n'
    local forks = jdat.forks_count == 1 and jdat.forks_count .. ' fork' or jdat.forks_count .. ' forks'
    local stargazers = jdat.stargazers_count == 1 and jdat.stargazers_count .. ' star' or jdat.stargazers_count .. ' stars'
    local subscribers = jdat.subscribers_count == 1 and jdat.subscribers_count .. ' watcher' or jdat.subscribers_count .. ' watchers'
    local output = string.format('%s%s<a href="%s/network">%s</a> <b>|</b> <a href="%s/stargazers">%s</a> <b>|</b> <a href="%s/watchers">%s</a>\nLast updated at %s.', title, description, jdat.html_url, forks, jdat.html_url, stargazers, jdat.html_url, subscribers, jdat.updated_at:gsub('T', ' '):gsub('Z', ''))
    return mattata.send_message(message.chat.id, output, 'html')
end

return github