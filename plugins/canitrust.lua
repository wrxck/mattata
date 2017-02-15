--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local canitrust = {}

local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local isup = require('plugins.isup')

function canitrust:init(configuration)
    assert(
        configuration.keys.canitrust,
        'canitrust.lua requires an API key, and you haven\'t got one configured!'
    )
    canitrust.commands = mattata.commands(
        self.info.username
    ):command('canitrust').table
    canitrust.help = [[/canitrust <url> - Reveals any known security issues with a website.]]
end

function canitrust:on_message(message, configuration)
    local input = mattata.input(message.text:lower())
    if not input then
        return mattata.send_reply(
            message,
            canitrust.help
        )
    end
    local jstr, res = https.request('https://api.mywot.com/0.4/public_link_json2?hosts=' .. url.escape(input) .. '&callback=process&key=' .. configuration.keys.canitrust)
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local output = ''
    if not isup.is_site_up(input) then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    if jstr:match('^process%({ "' .. input .. '": { "target": "' .. input .. '" } } %)$') then
        output = 'There are *no known issues* with this website.'
    elseif jstr:match('"101"') then
        output = 'This website is likely to contain *malware*.'
    elseif jstr:match('"102"') then
        output = 'This website is likely to provide a *poor customer experience*.'
    elseif jstr:match('"103"') then
        output = 'This website has been flagged as *phishing*.'
    elseif jstr:match('"104"') then
        output = 'This website has been flagged as *a scam*.'
    elseif jstr:match('"105"') then
        output = 'This website is *potentially illegal*.'
    elseif jstr:match('"201"') then
        output = 'This website is known to be *unethical*, and may provide *misleading claims*.'
    elseif jstr:match('"202"') then
        output = 'This website has been flagged as a *privacy risk*.'
    elseif jstr:match('"203"') then
        output = 'This website is *suspicious*.'
    elseif jstr:match('"204"') then
        output = 'This website has been flagged for containing *hate/discrimination*.'
    elseif jstr:match('"205"') then
        output = 'This website has been flagged as *spam*.'
    elseif jstr:match('"206"') then
        output = 'This website has been known to distribute *potentially unwanted programs*.'
    elseif jstr:match('"207"') then
        output = 'This website contains *ads/pop-ups*.'
    elseif jstr:match('"301"') then
        output = 'This website is known to *track your online activity*.'
    elseif jstr:match('"302"') then
        output = 'This website has been associated with *alternative or controversial medicine*.'
    elseif jstr:match('"303"') then
        output = 'This website is likely to contain *religious/political beliefs*.'
    elseif jstr:match('"401"') then
        output = 'This website contains *adult content*.'
    elseif jstr:match('"402"') then
        output = 'This website contains *incidental nudity*.'
    elseif jstr:match('"403"') then
        output = 'This website has been flagged as *gruesome or shocking*.'
    elseif jstr:match('"404"') then
        output = 'This website is *suitable for kids*.'
    elseif jstr:match('"501"') then
        output = 'There are *no known issues* with this website.'
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'markdown',
        true,
        false,
        nil,
        json.encode(
            {
                ['inline_keyboard'] = {
                    {
                        {
                            ['text'] = 'Proceed To Site',
                            ['url'] = input
                        }
                    }
                }
            }
        )
    )
end

return canitrust