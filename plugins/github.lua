--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local github = {}

local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function github:init()
    github.commands = mattata.commands(
        self.info.username
    ):command('github')
     :command('gh').table
    github.help = [[/github <GitHub username> <GitHub repository name> - Returns information about the specified GitHub repository. Alias: /gh.]]
end

function github:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            github.help
        )
    end
    input = input:gsub('%s', '/')
    local jstr, res = https.request('https://api.github.com/repos/' .. input)
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    if not jdat.id then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    local title = '[' .. mattata.escape_markdown(jdat.full_name) .. '](' .. jdat.html_url .. ') *|* ' .. jdat.language
    local description, forks, stargazers, subscribers
    if jdat.description then
        description = '\n' .. '```\n' .. mattata.escape_markdown(jdat.description) .. '\n```' .. '\n'
    else
        description = '\n\n'
    end
    if jdat.forks_count == 1 then
        forks = ' fork'
    else
        forks = ' forks'
    end
    if jdat.stargazers_count == 1 then
        stargazers = ' star'
    else
        stargazers = ' stars'
    end
    if jdat.subscribers_count == 1 then
        subscribers = ' watcher'
    else
        subscribers = ' watchers'
    end
    return mattata.send_message(
        message.chat.id,
        title .. description .. '[' .. jdat.forks_count .. forks .. '](' .. jdat.html_url .. '/network) *|* [' .. jdat.stargazers_count .. stargazers .. '](' .. jdat.html_url .. '/stargazers) *|* [' .. jdat.subscribers_count .. subscribers .. '](' .. jdat.html_url .. '/watchers) \nLast updated at ' .. jdat.updated_at:gsub('T', ' '):gsub('Z', ''),
        'markdown'
    )
end

return github