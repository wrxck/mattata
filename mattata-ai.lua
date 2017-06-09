--[[
                     _   _        _                    _
     _ __ ___   __ _| |_| |_ __ _| |_ __ _        __ _(_)
    | '_ ` _ \ / _` | __| __/ _` | __/ _` |_____ / _` | |
    | | | | | | (_| | |_| || (_| | || (_| |_____| (_| | |
    |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|      \__,_|_|

    Copyright (c) 2017 Matthew Hesketh
    See LICENSE for details

    mattata-ai is a basic AI implementation, hooked to Cleverbot, written in Lua.
    Intended for use with the mattata library, a feature-packed Telegram bot.

]]

local ai = {}
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')
local digest = require('openssl.digest')
local html = require('htmlEntities')
local redis = require('mattata-redis')
or false

function ai.num_to_hex(int)
    local hex = '0123456789abcdef'
    local s = ''
    while int > 0
    do
        local mod = math.fmod(int, 16)
        s = hex:sub(mod + 1, mod +1 ) .. s
        int = math.floor(int / 16)
    end
    if s == ''
    then
        s = '0'
    end
    return s
end

function ai.str_to_hex(str)
    local s = ''
    while #str > 0
    do
        local h = ai.num_to_hex(str:byte(1, 1))
        if #h < 2
        then
            h = '0' .. h
        end
        s = s .. h
        str = str:sub(2)
    end
    return s
end

function ai.unescape(str)
    if not str
    then
        return false
    end
    str = str:gsub(
        '%%(%x%x)',
        function(x)
            return tostring(
                tonumber(x, 16)
            ):char()
        end
    )
    return str
end

function ai.cleverbot_cookie()
    local cookie = {}
    local _, res, headers = http.request{
        ['url'] = 'http://www.cleverbot.com/',
        ['method'] = 'GET'
    }
    if res ~= 200
    then
        return false
    end
    local set = headers['set-cookie']
    local k, v = set:match('([^%s;=]+)=?([^%s;]*)')
    cookie[k] = v
    return cookie
end

function ai.talk(message, reply)
    if not message
    then
        return false
    end
    return ai.cleverbot(
        message,
        reply
    )
end

function ai.cleverbot(message, reply)
    local cookie = ai.cleverbot_cookie()
    if not cookie
    then
        return false
    end
    for k, v in pairs(cookie)
    do
        cookie[#cookie + 1] = k .. '=' .. v
    end
    local query = 'stimulus=' .. url.escape(message)
    if reply
    then
        query = query .. '&vText2=' .. url.escape(reply)
    end
    query = query .. '&cb_settings_scripting=no&islearning=1&icognoid=wsf&icognocheck='
    query = query .. ai.str_to_hex(
        digest.new('md5'):final(
            query:sub(8, 33)
        )
    )
    local _, res, headers = http.request(
        {
            ['url'] = 'http://www.cleverbot.com/webservicemin?uc=UseOfficialCleverbotAPI&',
            ['method'] = 'POST',
            ['headers'] = {
                ['Host'] = 'www.cleverbot.com',
                ['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:51.0) Gecko/20100101 Firefox/51.0',
                ['Accept'] = '*/*',
                ['Accept-Language'] = 'en-US,en;q=0.5',
                ['Accept-Encoding'] = 'gzip, deflate',
                ['Referrer'] = 'http://www.cleverbot.com/',
                ['Content-Length'] = query:len(),
                ['Content-Type'] = 'text/plain;charset=UTF-8',
                ['Cookie'] = table.concat(
                    cookie,
                    ';'
                ),
                ['DNT'] = '1',
                ['Connection'] = 'keep-alive'
            },
            ['source'] = ltn12.source.string(query)
        }
    )
    if res ~= 200
    or not headers.cboutput
    then
        return false
    end
    local output = ai.unescape(headers.cboutput)
    if not output
    then
        return false
    end
    return output
end

return ai