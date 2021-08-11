--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local medium = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function medium:init()
    medium.commands = mattata.commands(self.info.username):command('medium'):command('m').table
    medium.help = '/medium <query> - Returns Medium posts matching the given search query. Alias: /m.'
end

function medium.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, medium.help)
    end

    local json_data = medium.fetch_json_data(input)
    local posts = json_data.posts
    local lines = {}

    for i=1, math.min(#posts, 3) do
        local post = posts[i]
        local line = medium.build_line(post)
        table.insert(lines, line)
    end

    return mattata.send_reply(message, table.concat(lines, '\n\n'), 'markdown', true)
end

function medium.build_line(post)
    local title = post.title
    local preview = post.previewContent
    local subtitle = preview.subtitle
    local url = string.format('https://blog.discord.com/%s-%s', post.slug, post.id)

    return string.format('[%s](%s) - %s', title, url, subtitle)
end

function medium.fetch_json_data(input)
    local html, http_status = https.request('https://medium.com/search?q=' .. url.escape(input))
    if http_status ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end

    local json_str = html:match('<!%[CDATA%[\nwindow%["obvInit"%]%(({.-}})%)\n// %]%]>')
    if not json_str then
        return mattata.send_reply(message, language.errors.results)
    end

    return json.decode(json_str)
end

return medium