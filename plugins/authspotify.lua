--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local authspotify = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local ltn12 = require('ltn12')
local redis = require('libs.redis')

function authspotify:init(configuration)
    authspotify.commands = mattata.commands(self.info.username):command('authspotify').table
    authspotify.help = '/authspotify <token> - Authorises your Spotify account for use with mattata.'
    authspotify.redirect_uri = configuration.keys.spotify.redirect_uri
    authspotify.client_id = configuration.keys.spotify.client_id
    authspotify.client_secret = configuration.keys.spotify.client_secret
end

function authspotify.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, authspotify.help)
    elseif redis:get('spotify:' .. message.from.id .. ':access_token') then
        return mattata.send_reply(message, language['authspotify']['1'])
    end
    input = input:match('[%?&]code=(.-)$') or input
    local query = string.format('grant_type=authorization_code&code=%s&redirect_uri=%s&client_id=%s&client_secret=%s', url.escape(input), url.escape(authspotify.redirect_uri), authspotify.client_id, authspotify.client_secret)
    local wait_message = mattata.send_message(message.chat.id, language['authspotify']['2'])
    local response = {}
    local _, res = https.request({
        ['url'] = 'https://accounts.spotify.com/api/token',
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = query:len()
        },
        ['source'] = ltn12.source.string(query),
        ['sink'] = ltn12.sink.table(response)
    })
    local jdat = json.decode(table.concat(response))
    if res ~= 200 or not jdat or jdat.error then
        local output = string.format('%s `%s?code=...`', language['authspotify']['3'], authspotify.redirect_uri)
        return mattata.edit_message_text(message.chat.id, wait_message.result.message_id, output, true)
    end
    redis:set('spotify:' .. message.from.id .. ':access_token', jdat.access_token)
    redis:expire('spotify:' .. message.from.id .. ':access_token', 3600)
    redis:set('spotify:' .. message.from.id .. ':refresh_token', jdat.refresh_token)
    return mattata.edit_message_text(message.chat.id, wait_message.result.message_id, language['authspotify']['4'])
end

return authspotify