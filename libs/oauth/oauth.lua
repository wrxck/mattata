--[[
      An OAuth library for use with mattata, the feature-packed, multi-purpose Telegram bot.
      Based on LuaOAuth, by Ignacio Burgueño.

      Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
      See LICENSE for details
]]

local url = require('socket.url')
local b64 = require('base64')
local crypto = require('crypto')
local core = dofile('libs/oauth/core.lua')

local client = {}
client.__index = client

local valid_http_methods = {
    ['GET'] = true,
    ['HEAD'] = true,
    ['POST'] = true,
    ['PUT'] = true,
    ['DELETE'] = true
}

local replace_table = function(t1, t2)
    assert(t1)
    if not t2 then
        return t1
    end
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

local random = function(b)
    local r = assert(io.open('/dev/urandom', 'rb'))
    b = tonumber(b) ~= nil and tonumber(b) or 4
    local s = r:read(b)
    assert(s:len() == b)
    local v = 0
    for i = 1, b do
        v = 256 * v + s:byte(i)
    end
    return v
end

local generate_nonce = function(key)
    key = key and tostring(key) or 'keyyyy'
    local nonce = tostring(random(math.random(10000)))
    return crypto.hmac.digest('sha1', nonce, key)
end

local oauth_encode = function(val)
    return tostring(val):gsub('[^-._~a-zA-Z0-9]', function(letter)
        return string.format('%%%02x', letter:byte()):upper()
    end)
end

url.unescape = function(s)
    return s:gsub('%%(%x%x)', function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

function client:sign(http_method, base_uri, arguments, oauth_token_secret, auth_realm)
    assert(valid_http_methods[http_method], 'The method "' .. http_method .. '" is not supported!')
    local consumer_secret = self.consumer_secret_meta
    local token_secret = oauth_token_secret or ''
    local all_values = {}
    for k, v in pairs(arguments) do
        table.insert(all_values, {
            ['key'] = oauth_encode(k),
            ['value'] = oauth_encode(tostring(v))
        })
    end
    table.sort(all_values, function(a, b)
        if a.key < b.key then
            return true
        elseif a.key > b.key then
            return false
        else
            return a.value < b.value
        end
    end)
    local combined_values = {}
    for _, pair in pairs(all_values) do
        table.insert(combined_values, pair.key .. '=' .. pair.value)
    end
    local query_string_except_signature = table.concat(combined_values, '&')
    local signature_base_string = http_method .. '&' .. oauth_encode(base_uri) .. '&' .. oauth_encode(query_string_except_signature)
    local signature_key = oauth_encode(consumer_secret) .. '&' .. oauth_encode(token_secret)
    local hmac_binary = crypto.hmac.digest('sha1', signature_base_string, signature_key, true)
    local hmac_b64 = b64.encode(hmac_binary)
    local oauth_signature = oauth_encode(hmac_b64)
    local oauth_headers
    if self.supports_auth_header_meta then
        oauth_headers = string.format('OAuth realm="%s"', auth_realm or '')
        oauth_headers = { oauth_headers }
        for k, v in pairs(arguments) do
            if k:match('^oauth_') then
                table.insert(oauth_headers, k .. '="' .. oauth_encode(v) .. '"')
            end
        end
        table.insert(oauth_headers, 'oauth_signature="' .. oauth_signature .. '"')
        oauth_headers = table.concat(oauth_headers, ', ')
    end
    return oauth_signature, query_string_except_signature .. '&oauth_signature=' .. oauth_signature, oauth_headers
end

local perform_request_helper = function(self, url, method, headers, arguments, post_body, callback)
    if type(arguments) == 'table' then
        for k, v in pairs(arguments) do
            if type(k) == 'string' and k:match('^OAuth_') then
                arguments[k] = nil
            end
        end
        if not next(arguments) then
            arguments = nil
        end
    end
    return core.perform_request_helper(self, url, method, headers, arguments, post_body, callback)
end

function client:request_token(arguments, headers, callback)
    if type(arguments) == 'function' then
        callback = arguments
        arguments, headers = nil, nil
    elseif type(headers) == 'function' then
        callback = headers
        headers = nil
    end
    local new_arguments = {
        ['oauth_consumer_key'] = self.consumer_key_meta,
        ['oauth_nonce'] = generate_nonce(),
        ['oauth_signature_method'] = self.signature_method_meta,
        ['oauth_timestamp'] = tostring(os.time()),
        ['oauth_version'] = '1.0'
    }
    new_arguments = replace_table(new_arguments, arguments)
    local endpoint = self.endpoints_meta['RequestToken']
    local oauth_signature, post_body, auth_header = self:sign(endpoint.method, endpoint.url, new_arguments)
    local headers = replace_table({}, headers)
    if self.supports_auth_header_meta then
        headers['Authorization'] = auth_header
    end
    if not callback then
        local ok, response_code, response_headers, response_status_line, response_body = perform_request_helper(self, endpoint.url, endpoint.method, headers, arguments, post_body)
        if not ok or response_code ~= 200 then
            return nil, response_code, response_headers, response_status_line, response_body
        end
        local values = {}
        for k, v in response_body:gmatch('([^&=]+)=([^&=]*)&?') do
            values[k] = url.unescape(v)
        end
        self.oauth_token_secret_meta = values.oauth_token_secret
        self.oauth_token_meta = values.oauth_token
        return values
    else
        local oauth_instance = self
        local on_error = function(err, response_code, response_headers, response_status_line, response_body)
            if err then
                return callback(err)
            elseif response_code ~= 200 then
                local payload = {
                    ['status'] = response_code,
                    ['headers'] = response_headers,
                    ['status_line'] = response_status_line,
                    ['body'] = response_body
                }
                callback(payload)
            end
            local values = {}
            for k, v in response_body:gmatch('([^&=]+)=([^&=]*)&?') do
                values[k] = url.unescape(v)
            end
            oauth_instance.oauth_token_secret_meta = values.oauth_token_secret
            oauth_instance.oauth_token_meta = values.oauth_token
            callback(nil, values)
        end
        perform_request_helper(self, endpoint.url, endpoint.method, headers, arguments, post_body, on_error)
    end
end

function client:build_auth_url(arguments)
    local new_arguments = {}
    new_arguments = replace_table(new_arguments, arguments)
    new_arguments.oauth_token = (arguments and arguments.oauth_token) or self.oauth_token_meta or error('No `oauth_token`!')
    local all_values = {}
    for k, v in pairs(new_arguments) do
        table.insert(all_values, {
            ['key'] = oauth_encode(k),
            ['value'] = oauth_encode(tostring(v))
        })
    end
    local combined_values = {}
    for _, pair in pairs(all_values) do
        table.insert(combined_values, pair.key .. '=' .. pair.value)
    end
    local query_string = table.concat(combined_values, '&')
    local endpoint = self.endpoints_meta['AuthorizeUser']
    return endpoint.url .. '?' .. query_string
end

function client:get_access_token(arguments, headers, callback)
    if type(arguments) == 'function' then
        callback = arguments
        arguments, headers = nil, nil
    elseif type(headers) == 'function' then
        callback = headers
        headers = nil
    end
    local arguments = {
        ['oauth_consumer_key'] = self.consumer_key_meta,
        ['oauth_nonce'] = generate_nonce(),
        ['oauth_signature_method'] = self.signature_method_meta,
        ['oauth_timestamp'] = tostring(os.time()),
        ['oauth_version'] = '1.0',
    }
    arguments.oauth_token = (arguments and arguments.oauth_token) or self.oauth_token_meta or error('No `oauth_token`!')
    arguments.oauth_verifier = (arguments and arguments.oauth_verifier) or self.oauth_verifier_meta
    local endpoint = self.endpoints_meta['AccessToken']
    local oauth_token_secret = (arguments and arguments.oauth_token_secret) or self.oauth_token_secret_meta or error('No `oauth_token_secret`!')
    arguments.oauth_token_secret = nil
    local oauth_signature, post_body, auth_header = self:sign(endpoint.method, endpoint.url, arguments, oauth_token_secret)
    local headers = replace_table({}, headers)
    if self.supports_auth_header_meta then
        headers['Authorization'] = auth_header
    end
    if not callback then
        local ok, response_code, response_headers, response_status_line, response_body = perform_request_helper(self, endpoint.url, endpoint.method, headers, arguments, post_body)
        if not ok or response_code ~= 200 then
            return nil, response_code, response_headers, response_status_line, response_body
        end
        local values = {}
        for k, v in response_body:gmatch('([^&=]+)=([^&=]*)&?') do
            values[k] = url.unescape(v)
        end
        self.oauth_token_secret_meta = values.oauth_token_secret
        self.oauth_token_meta = values.oauth_token
        return values
    else
        local oauth_instance = self
        local on_error = function(err, response_code, response_headers, response_status_line, response_body)
            if err then
                return callback(err)
            end
            if response_code ~= 200 then
                local payload = {
                    ['status'] = response_code,
                    ['headers'] = response_headers,
                    ['status_line'] = response_status_line,
                    ['body'] = response_body
                }
                return callback(payload)
            end
            local values = {}
            for k, v in response_body:gmatch('([^&=]+)=([^&=]*)&?') do
                values[k] = url.unescape(v)
            end
            oauth_instance.oauth_token_secret_meta = values.oauth_token_secret
            oauth_instance.oauth_token_meta = values.oauth_token
            callback(nil, values)
        end
        perform_request_helper(self, endpoint.url, endpoint.method, headers, arguments, post_body, on_error)
    end
end

function client:perform_request(method, url, arguments, headers, callback)
    assert(type(method) == 'string', '`method` must be a string!')
    method = method:upper()
    if type(arguments) == 'function' then
        callback = arguments
        arguments, headers = nil, nil
    elseif type(headers) == 'function' then
        callback = headers
        headers = nil
    end
    local headers, arguments, post_body = self:build_request(method, url, arguments, headers)
    if not callback then
        local ok, response_code, response_headers, response_status_line, response_body = perform_request_helper(self, url, method, headers, arguments, post_body)
        return response_code, response_headers, response_status_line, response_body
    else
        perform_request_helper(self, url, method, headers, arguments, post_body, callback)
    end
end

function client:build_request(method, url, arguments, headers)
    assert(type(method) == 'string', '`method` must be a string!')
    method = method:upper()
    local new_arguments = {
        ['oauth_consumer_key'] = self.consumer_key_meta,
        ['oauth_nonce'] = generate_nonce(),
        ['oauth_signature_method'] = self.signature_method_meta,
        ['oauth_timestamp'] = tostring(os.time()),
        ['oauth_version'] = '1.0'
    }
    local is_table = type(arguments) == 'table'
    if is_table then
        new_arguments = replace_table(new_arguments, arguments)
    end
    new_arguments.oauth_token = (is_table and arguments.oauth_token) or self.oauth_token_meta or error('No `oauth_token`!')
    local oauth_token_secret = (is_table and arguments.oauth_token_secret) or self.oauth_token_secret_meta or error('No `oauth_token_secret`!')
    if is_table then
        arguments.oauth_token_secret = nil
    end
    new_arguments.oauth_token_secret = nil
    local oauth_signature, post_body, auth_header = self:sign(method, url, new_arguments, oauth_token_secret)
    local headers = replace_table({}, headers)
    if self.supports_auth_header_meta then
        headers['Authorization'] = auth_header
    end
    if type(arguments) == 'table' then
        for k, v in pairs(arguments) do
            if type(k) == 'string' and k:match('^oauth_') then
                arguments[k] = nil
            end
        end
        if not next(arguments) then
            arguments = nil
        end
    end
    return headers, arguments, post_body
end

function client:set_token(value)
    self.oauth_token_meta = value
end

function client:get_token()
    return self.oauth_token_meta
end

function client:set_token_secret(value)
    self.oauth_token_secret_meta = value
end

function client:get_token_secret()
    return self.oauth_token_secret_meta
end

function client:set_verifier(value)
    self.oauth_verifier_meta = value
end

function client:get_verifier()
    return self.oauth_verifier_meta
end

function client.new(consumer_key, consumer_secret, endpoints, parameters)
    parameters = parameters or {}
    local new_instance = {
        ['consumer_key_meta'] = consumer_key,
        ['consumer_secret_meta'] = consumer_secret,
        ['endpoints_meta'] = {},
        ['signature_method_meta'] = parameters['SignatureMethod'] or 'HMAC-SHA1',
        ['supports_auth_header_meta'] = true,
        ['oauth_token_meta'] = parameters['OAuthToken'],
        ['oauth_token_secret_meta'] = parameters['OAuthTokenSecret'],
        ['oauth_verifier_meta'] = parameters['OAuthVerifier']
    }
    if type(parameters.use_auth_headers) == 'boolean' then
        new_instance.supports_auth_header_meta = parameters['UseAuthHeaders']
    end
    for k, v in pairs(endpoints or {}) do
        if type(v) == 'table' then
            new_instance.endpoints_meta[k] = {
                ['url'] = v[1],
                ['method'] = string.upper(v.method)
            }
        else
            new_instance.endpoints_meta[k] = {
                ['url'] = v,
                ['method'] = 'POST'
            }
        end
    end
    setmetatable(new_instance, client)
    return new_instance
end

return client