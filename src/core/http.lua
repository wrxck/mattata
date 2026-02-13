--[[
    mattata v2.1 - Async HTTP Module
    Provides copas-compatible non-blocking HTTP requests.
    Uses copas.http which wraps luasocket with async I/O.
    Includes retry with exponential backoff for transient failures.
]]

local http_mod = {}

local copas = require('copas')
local http = require('copas.http')
local ltn12 = require('ltn12')
local logger = require('src.core.logger')

local DEFAULT_HEADERS = {
    ['User-Agent'] = 'mattata-telegram-bot/2.1'
}

local DEFAULT_TIMEOUT = 10        -- seconds
local DEFAULT_MAX_RETRIES = 2     -- total attempts = 1 + retries
local INITIAL_BACKOFF = 0.5       -- seconds
local MAX_BACKOFF = 8             -- seconds

-- Codes that should be retried
local RETRYABLE_CODES = { [429] = true, [500] = true, [502] = true, [503] = true, [504] = true }

local function merge_headers(custom)
    local headers = {}
    for k, v in pairs(DEFAULT_HEADERS) do headers[k] = v end
    if custom then
        for k, v in pairs(custom) do headers[k] = v end
    end
    return headers
end

function http_mod.request(opts)
    local max_retries = opts.max_retries or DEFAULT_MAX_RETRIES
    local timeout = opts.timeout or DEFAULT_TIMEOUT
    local backoff = INITIAL_BACKOFF

    for attempt = 1, max_retries + 1 do
        local body = {}
        local request_opts = {
            url = opts.url,
            method = opts.method or 'GET',
            headers = merge_headers(opts.headers),
            sink = ltn12.sink.table(body),
            source = opts.source,
            redirect = opts.redirect ~= false,
            create = function()
                local tcp = copas.wrap(require('socket').tcp())
                tcp:settimeout(timeout)
                return tcp
            end
        }

        local ok, code_or_err, response_headers = pcall(http.request, request_opts)

        if not ok then
            -- Network error (timeout, connection refused, etc.)
            if attempt <= max_retries then
                logger.warn('HTTP %s %s attempt %d failed: %s — retrying in %.1fs',
                    opts.method or 'GET', opts.url, attempt, tostring(code_or_err), backoff)
                copas.pause(backoff)
                backoff = math.min(backoff * 2, MAX_BACKOFF)
            else
                logger.error('HTTP %s %s failed after %d attempts: %s',
                    opts.method or 'GET', opts.url, attempt, tostring(code_or_err))
                return '', 0, {}
            end
        else
            local code = code_or_err
            -- Check for retryable HTTP status codes
            if RETRYABLE_CODES[code] and attempt <= max_retries then
                -- Respect Retry-After header for 429
                local retry_after = response_headers and response_headers['retry-after']
                local wait = tonumber(retry_after) or backoff
                wait = math.min(wait, MAX_BACKOFF)
                logger.warn('HTTP %s %s returned %d — retrying in %.1fs',
                    opts.method or 'GET', opts.url, code, wait)
                copas.pause(wait)
                backoff = math.min(backoff * 2, MAX_BACKOFF)
            else
                return table.concat(body), code, response_headers
            end
        end
    end

    return '', 0, {}
end

function http_mod.get(url, headers)
    return http_mod.request({ url = url, headers = headers })
end

function http_mod.post(url, post_body, content_type, headers)
    headers = headers or {}
    headers['Content-Type'] = content_type or 'application/x-www-form-urlencoded'
    headers['Content-Length'] = tostring(#post_body)
    return http_mod.request({
        url = url,
        method = 'POST',
        headers = headers,
        source = ltn12.source.string(post_body)
    })
end

function http_mod.get_json(url, headers)
    local json = require('dkjson')
    local body, code = http_mod.get(url, headers)
    if code ~= 200 then
        return nil, code
    end
    local data, _, err = json.decode(body)
    if err then
        return nil, 'JSON parse error: ' .. tostring(err)
    end
    return data, code
end

return http_mod
