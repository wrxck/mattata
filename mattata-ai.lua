--[[
                     _   _        _                    _
     _ __ ___   __ _| |_| |_ __ _| |_ __ _        __ _(_)
    | '_ ` _ \ / _` | __| __/ _` | __/ _` |_____ / _` | |
    | | | | | | (_| | |_| || (_| | || (_| |_____| (_| | |
    |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|      \__,_|_|

    Copyright (c) 2017 Matthew Hesketh
    See LICENSE for details

    mattata-ai is a basic AI implementation, hooked to Mitsuku and Cleverbot, written in Lua.
    Intended for use with the mattata library, a feature-packed Telegram bot API framework.

]]

local ai = {}

local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local redis = require('mattata-redis') or false
local json = require('dkjson')
local digest = require('openssl.digest')
local html = require('htmlEntities')

function ai.num_to_hex(int)
    local hex = '0123456789abcdef'
    local s = ''
    while int > 0 do
        local mod = math.fmod(int, 16)
        s = hex:sub(mod + 1, mod +1 ) .. s
        int = math.floor(int / 16)
    end
    if s == '' then
        s = '0'
    end
    return s
end

function ai.str_to_hex(str)
    local s = ''
    while #str > 0 do
        local h = ai.num_to_hex(str:byte(1, 1))
        if #h < 2 then
            h = '0' .. h
        end
        s = s .. h
        str = str:sub(2)
    end
    return s
end

function ai.unescape(str)
    if not str then
        return false
    end
    str = str:gsub(
        '%%(%x%x)',
        function(x)
            return tostring(tonumber(x, 16)):char()
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
    if res ~= 200 then
        return false
    end
    local set = headers['set-cookie']
    local k, v = set:match('([^%s;=]+)=?([^%s;]*)')
    cookie[k] = v
    return cookie
end

function ai.mitsuku_cookie()
    local _, res, headers = https.request('https://kakko.pandorabots.com/pandora/talk?botid=f326d0be8e345a13&skin=chat')
    if res ~= 200 then
        return false
    end
    return headers['set-cookie']:match('^(.-%;)')
end

function ai.mitsuku(message, user_id)
    local cookie
    if redis then
        cookie = redis:hget(
            'ai:cookie',
            user_id
        )
    end
    if not cookie then
        cookie = ai.mitsuku_cookie()
        if not cookie then
            return false
        elseif redis then
            redis:hset(
                'ai:cookie',
                user_id,
                cookie
            )
        end
    end
    local query = 'botcust2=' .. cookie .. '&message=' .. message:gsub('%s', '+')
    local response = {}
    local _, res = https.request{
        ['url'] = 'https://kakko.pandorabots.com/pandora/talk?botid=f326d0be8e345a13&skin=chat',
        ['method'] = 'POST',
        ['headers'] = {
            ['Host'] = 'kakko.pandorabots.com',
            ['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:51.0) Gecko/20100101 Firefox/51.0',
            ['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            ['Accept-Language'] = 'en-US,en;q=0.5',
            ['Referer'] = 'https://kakko.pandorabots.com/pandora/talk?botid=f326d0be8e345a13&skin=chat',
            ['Cookie'] = cookie,
            ['Content-Type'] = 'application/x-www-form-urlencoded',
            ['Content-Length'] = query:len()
        },
        ['source'] = ltn12.source.string(query),
        ['sink'] = ltn12.sink.table(response)
    }
    if res ~= 200 then
        return false
    end
    response = table.concat(response):match('^.-%<FONT FACE%=%"Trebuchet MS.-Arial%" COLOR%=%"%#%d+%"%>.-%:.-%:(.-)%<br%>.-%<br%>')
    if not response then
        return false
    end
    response = response:gsub('<br>', '\n')
                       :gsub('%b<>', '')
                       :gsub('[Mm][Ii][Tt][Ss][Uu][Kk][Uu]', 'mattata')
                       :gsub('(%a[%,%!%:])(%a)', '%1 %2')
                       :gsub('^%s*(.-)%s*$', '%1')
                       :gsub('[Ss][Tt][Ee][Vv][Ee] [Ww][Oo][Rr][Ss][Ww][Ii][Cc][Kk]', 'Matthew Hesketh')
                       :gsub('[Ss][Qq][Uu][Aa][Rr][Ee] [Bb][Ee][Aa][Rr]', '@wrxck')
                       :gsub('[Mm][Oo][Uu][Ss][Ee][Bb][Rr][Ee][Aa][Kk][Ee][Rr]', 'Matt')
                       :gsub(' (%W)$', '%1')
                       :gsub('%b[]', '')
    return html.decode(response)
end

function ai.talk(message, reply, legacy, user_id)
    user_id = user_id or 1
    if not message then
        return false
    elseif legacy then
        return ai.cleverbot(
            message,
            reply
        )
    end
    return ai.mitsuku(
        message,
        user_id
    )
end

function ai.cleverbot(message, reply)
    local cookie = ai.cleverbot_cookie()
    if not cookie then
        return false
    end
    for k, v in pairs(cookie) do
        cookie[#cookie + 1] = k .. '=' .. v
    end
    local query = 'stimulus=' .. url.escape(message)
    if reply then
        query = query .. '&vText2=' .. url.escape(reply)
    end
    query = query .. '&cb_settings_scripting=no&islearning=1&icognoid=wsf&icognocheck='
    query = query .. ai.str_to_hex(
        digest.new('md5'):final(
            query:sub(8, 33)
        )
    )
    local _, res, headers = http.request{
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
    if res ~= 200 or not headers.cboutput then
        return false
    end
    local output = ai.unescape(headers.cboutput)
    if not output then
        return false
    end
    return output
end

return ai