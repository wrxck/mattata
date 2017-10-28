--[[
      An OAuth library for use with mattata, the feature-packed, multi-purpose Telegram bot.
      Based on LuaOAuth, by Ignacio Burgueño.

      Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
      See LICENSE for details
]]

local url = require('socket.url')
local _M = {}

_M.url_encode_arguments = function(arguments)
    local body = {}
    for k, v in pairs(arguments) do
        body[#body + 1] = url.escape(tostring(k)) .. '=' .. url.escape(tostring(v))
    end
    return table.concat(body, '&')
end

do
    local fmt = function(p, ...)
        return select('#', ...) == 0 and p or string.format(p, ...)
    end

    local tprintf = function(t, p, ...)
        t[#t + 1] = fmt(p, ...)
    end

    local append_data = function(r, k, data, extra)
        tprintf(r, 'content-disposition: form-data; name="%s"', k)
        if extra.filename then
            tprintf(r, '; filename="%s"', extra.filename)
        end
        if extra.content_type then
            tprintf(r, '\r\ncontent-type: %s', extra.content_type)
        end
        if extra.content_transfer_encoding then
            tprintf(r, '\r\ncontent-transfer-encoding: %s', extra.content_transfer_encoding)
        end
        tprintf(r, '\r\n\r\n')
        tprintf(r, data)
        tprintf(r, '\r\n')
    end

    local gen_boundary = function()
        local t = { 'BOUNDARY-' }
        for i = 2, 17 do
            t[i] = string.char(math.random(65, 90))
        end
        t[18] = '-BOUNDARY'
        return table.concat(t)
    end

    local encode = function(t, boundary)
        local r = {}
        local _t, _tkey, key
        boundary = boundary or gen_boundary()
        for k, v in pairs(t) do
            tprintf(r, '--%s\r\n', boundary)
            _tkey = type(k)
            _t = type(v)
            if _tkey ~= 'string' and _tkey ~= 'number' and _tkey ~= 'boolean' then
                local error_message = string.format('Unexpected type "%s" for key "%s"!', _tkey, tostring(k))
                return nil, error_message
            end
            if _t == 'string' then
                append_data(r, k, v, {})
            elseif _t == 'number' or _t == 'boolean' then
                append_data(r, k, tostring(v), {})
            elseif _t == 'table' then
                assert(v.data, 'Invalid input!')
                local extra = {
                    ['filename'] = v.filename or v.name,
                    ['content_type'] = v.content_type or v.mimetype or 'application/octet-stream',
                    ['content_transfer_encoding'] = v.content_transfer_encoding or 'binary',
                }
                append_data(r, k, v.data, extra)
            else
                local error_message = string.format('Unexpected type "%s" for value at key "%s"!', _t, tostring(k))
                return nil, error_message
            end
        end
        tprintf(r, '--%s--\r\n', boundary)
        return table.concat(r)
    end

    _M.multipart = {
        request = function(t)
            local boundary = gen_boundary()
            local body, err = encode(t, boundary)
            if not body then
                return body, err
            end
            return {
                ['body'] = body,
                ['headers'] = {
                    ['Content-Length'] = #body,
                    ['Content-Type'] = string.format('multipart/form-data; boundary=%s', boundary),
                },
            }
        end
    }
end

return _M