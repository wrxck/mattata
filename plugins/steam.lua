--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local steam = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')

function steam:init()
    steam.commands = mattata.commands(
        self.info.username
    ):command('steam')
     :command('setsteam').table
    steam.help = [[/steam [username] - Displays information about the given Steam user. If no username is specified then information about your Steam account (if applicable) is sent.]]
end

function steam.search(input, key)
    local jstr, res = https.request('https://steamcommunity.com/id/' .. url.escape(input))
    if res ~= 200 then
        return false, true
    end
    jstr = jstr:match('g%_rgProfileData %= (.-)%;')
    if not jstr or not jstr:match('^%{.-%}$') then
        return true, false
    end
    local jdat = json.decode(jstr)
    if not jdat or not jdat.steamid then
        return true, false
    end
    return steam.get_info(
        jdat.steamid,
        key
    ), true
end

function steam.get_info(id, key)
    local jstr, res = http.request('http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=' .. key .. '&steamids=' .. id)
    if res ~= 200 then
        return false
    end
    return jstr
end

function steam.get_username(id)
    return redis:hget(
        'steam:' .. id,
        'username'
    )
end

function steam.set_username(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            steam.help
        )
    end
    redis:hset(
        'steam:' .. message.from.id,
        'username',
        input
    )
    return mattata.send_reply(
        message,
        'Your Steam username has been set to "' .. input .. '".'
    )
end

function steam.format_output(jdat)
    if not jdat.response or not jdat.response.players or not jdat.response.players[1] then
        return false
    end
    local name = mattata.escape_html(jdat.response.players[1].personaname)
    if jdat.response.players[1].realname then
        name = mattata.escape_html(jdat.response.players[1].realname)
    end
    name = string.format(
        '<a href="%s">%s</a>',
        jdat.response.players[1].avatarfull,
        name
    )
    if jdat.response.players[1].realname and jdat.response.players[1].realname ~= jdat.response.players[1].personaname then
        name = string.format(
            '%s, AKA "%s",',
            name,
            jdat.response.players[1].personaname
        )
    end
    local output = string.format(
        '%s has been a user on Steam since %s, on %s. They last logged off at %s, on %s. Click <a href="%s">here</a> to view their Steam profile.',
        name,
        os.date('%X', jdat.response.players[1].timecreated),
        os.date('%x', jdat.response.players[1].timecreated),
        os.date('%X', jdat.response.players[1].lastlogoff),
        os.date('%x', jdat.response.players[1].lastlogoff),
        jdat.response.players[1].profileurl
    )
    if not output then
        return false
    end
    return output
end

function steam:on_message(message, configuration)
    if message.text:match('^%/se') then
        return steam.set_username(message)
    end
    local input = mattata.input(message.text)
    if not input and not steam.get_username(message.from.id) then
        return mattata.send_reply(
            message,
            steam.help
        )
    elseif not input then
        input = steam.get_username(message.from.id)
    end
    if input:match('^%@.-$') then
        input = input:match('^%@(.-)$')
    end
    local output, res = steam.search(
        input,
        configuration.keys.steam
    )
    if not output then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    elseif not res then
        return mattata.send_reply(
            message,
            '"' .. input .. '" isn\'t a valid Steam username.'
        )
    end
    output = steam.format_output(json.decode(output))
    if not output then
        return mattata.send_reply(
            message,
            '"' .. input .. '" isn\'t a valid Steam username.'
        )
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html',
        false
    )
end

return steam