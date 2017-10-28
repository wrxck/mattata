--[[
      An OAuth library for use with mattata, the feature-packed, multi-purpose Telegram bot.
      Based on LuaOAuth, by Ignacio Burgueño.

      Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
      See LICENSE for details
]]

local ltn12 = require('ltn12')
local http = require('socket.http')
local https = require('ssl.https')
local helpers = dofile('libs/oauth/helpers.lua')

local _M = {}

function _M.perform_request_helper(self, url, method, headers, arguments, post_body, content_type)
    local response_body = {}
    local request_constructor = {
        ['url'] = url,
        ['method'] = method,
        ['headers'] = headers,
        ['sink'] = ltn12.sink.table(response_body),
        ['redirect'] = false
    }
    if method == 'PUT' then
        if type(arguments) == 'table' then
            error('Unsupported table argument for the PUT method!')
        else
            local string_data = tostring(arguments)
            if string_data == 'nil' then
                error('Arguments cannot be a nil string value!')
            end
            request_constructor.headers['Content-Length'] = tostring(#string_data)
            request_constructor.source = ltn12.source.string(string_data)
        end
    elseif method == 'POST' then
        if type(arguments) == 'table' then
            request_constructor.headers['Content-Type'] = content_type and tostring(content_type) or 'application/x-www-form-urlencoded'
            if not self.supports_auth_header_meta then
                request_constructor.headers['Content-Length'] = tostring(#post_body)
                request_constructor.source = ltn12.source.string(post_body)
            else
                local source = helpers.url_encode_arguments(arguments)
                request_constructor.headers['Content-Length'] = tostring(#source)
                request_constructor.source = ltn12.source.string(source)
            end
        elseif arguments then
            if not self.supports_auth_header_meta then
                error('POST body cannot be sent if the server does not support the `Authorization` header!')
            end
            local string_data = tostring(arguments)
            if string_data == 'nil' then
                error('Arguments cannot be a nil string value!')
            end
            request_constructor.headers['Content-Length'] = tostring(#string_data)
            request_constructor.source = ltn12.source.string(string_data)
        else
            request_constructor.headers['Content-Length'] = '0'
        end
    elseif method == 'GET' or method == 'HEAD' or method == 'DELETE' then
        if self.supports_auth_header_meta then
            if arguments then
                request_constructor.url = url .. '?' .. helpers.url_encode_arguments(arguments)
            end
        else
            request_constructor.url = url .. '?' .. post_body
        end
    end
    local ok, response_code, response_headers, response_status_line
    if url:match('^https://') then
        ok, response_code, response_headers, response_status_line = https.request(request_constructor)
    elseif url:match('^http://') then
        ok, response_code, response_headers, response_status_line = http.request(request_constructor)
    else
        local scheme = tostring(url:match('^([^:]+)'))
        local error_message = string.format('Unsupported scheme "%s"!', scheme)
        error(error_message)
    end
    if not ok then
        return nil, response_code, response_headers, response_status_line, response_body
    end
    response_body = table.concat(response_body)
    return true, response_code, response_headers, response_status_line, response_body
end

return _M