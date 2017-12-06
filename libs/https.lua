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
    request = type(request) == 'string' and https.build_table(request, body, result) or https.build_url(request.url)
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