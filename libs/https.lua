--[[

    Customised version of https://github.com/brunoos/luasec/blob/master/src/https.lua to allow better timeouts.

    LuaSec 0.9 license
    Copyright (C) 2006-2019 Bruno Silvestre, UFG

    Permission is hereby granted, free  of charge, to any person obtaining
    a  copy  of this  software  and  associated  documentation files  (the
    "Software"), to  deal in  the Software without  restriction, including
    without limitation  the rights to  use, copy, modify,  merge, publish,
    distribute,  sublicense, and/or sell  copies of  the Software,  and to
    permit persons to whom the Software  is furnished to do so, subject to
    the following conditions:

    The  above  copyright  notice  and  this permission  notice  shall  be
    included in all copies or substantial portions of the Software.

    THE  SOFTWARE IS  PROVIDED  "AS  IS", WITHOUT  WARRANTY  OF ANY  KIND,
    EXPRESS OR  IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE  WARRANTIES OF
    MERCHANTABILITY,    FITNESS    FOR    A   PARTICULAR    PURPOSE    AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]

local socket = require('socket')
local ssl = require('ssl')
local ltn12 = require('ltn12')
local http = require('socket.http')
local url = require('socket.url')

local https = {
    ['try'] = socket.try,
    ['configuration'] = {
        ['protocol'] = 'any',
        ['options'] = {
            'all',
            'no_sslv2',
            'no_sslv3'
        },
        ['verify'] = 'none'
    }
}

function https.build_url(request)
    local parsed = url.parse(request, { ['port'] = 443 })
    return url.build(parsed)
end

function https.build_table(request, body, result, method)
    request = {
        ['url'] = https.build_url(request),
        ['method'] = method or (body and 'POST' or 'GET'),
        ['sink'] = ltn12.sink.table(result)
    }
    if body then
        request.source = ltn12.source.string(body)
        request.headers = {
            ['Content-Length'] = #body,
            ['Content-Type'] = 'application/x-www-form-urlencoded'
        }
    end
    return request
end

function https.register(connection)
    for name, method in pairs(getmetatable(connection.socket).__index) do
        if type(method) == 'function' then
            connection[name] = function(self, ...)
                return method(self.socket, ...)
            end
        end
    end
end

function https.tcp(parameters, timeout)
    parameters = type(parameters) == 'table' and parameters or {}
    for k, v in pairs(https.configuration) do
        parameters[k] = parameters[k] or v
    end
    parameters.mode = 'client'
    return function()
        local connection = {}
        connection.socket = https.try(socket.tcp())
        https.settimeout = getmetatable(connection.socket).__index.settimeout
        function connection:settimeout(...)
            return https.settimeout(self.socket, ...)
        end
        function connection:connect(host, port)
            https.try(self.socket:connect(host, port))
            self.socket = https.try(ssl.wrap(self.socket, parameters))
            self.socket:sni(host)
            if timeout and tonumber(timeout) ~= nil then
                self.socket:settimeout(tonumber(timeout))
            end
            https.try(self.socket:dohandshake())
            https.register(self, getmetatable(self.socket))
            return 1
        end
        return connection
    end
end

function https.request(request, body, timeout)
    local result = {}
    request = type(request) == 'string' and https.build_table(request, body, result) or request
    timeout = https.timeout or request.timeout or timeout or nil
    if http.PROXY or request.proxy then
        return nil, 'Proxies are not supported!'
    elseif request.redirect then
        return nil, 'Redirects are not supported!'
    elseif request.create then
        return nil, 'The create function is not supported!'
    end
    request.create = https.tcp(request, timeout)
    local res, code, headers, status = http.request(request)
    if res and type(result) == 'table' then
        res = table.concat(result)
    end
    return res, code, headers, status
end

return https