--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local netflix = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function netflix:init(configuration)
    netflix.arguments = 'netflix <query>'
    netflix.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('netflix').table
    netflix.help = '/netflix <query> - Search Netflix for the given query.'
end

function netflix.send_request(input)
    local jstr, res = http.request('http://netflixroulette.net/api/api.php?title=' .. url.escape(input))
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if jdat.errorcode then
        return false
    end
    local output = {}
    table.insert(
        output,
        '<b>' .. mattata.escape_html(jdat.show_title) .. '</b>\n'
    )
    table.insert(
        output,
        '📅 ' .. jdat.release_year .. ' | ⭐ ' .. jdat.rating .. ' | ' .. mattata.escape_html(jdat.show_cast)
    )
    table.insert(
        output,
        '\n<i>' .. mattata.escape_html(jdat.summary) .. '</i>'
    )
    table.insert(
        output,
        '\n<a href="https://www.netflix.com/title/' .. jdat.show_id .. '">Read more.</a>'
    )
    return table.concat(
        output,
        '\n'
    )
end

function netflix:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            netflix.help
        )
    end
    local output = netflix.send_request(input)
    if not output then
        return mattata.send_reply(
            message,
            language.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return netflix