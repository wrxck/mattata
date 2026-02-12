--[[
    mattata v2.0 - Redis Connection Module
    Redis is used as cache/session store only. PostgreSQL is the primary database.
    Includes automatic reconnection with backoff, SCAN replacement for KEYS, and pipeline support.
]]

local redis_mod = {}

local redis_lib = require('redis')
local config = require('src.core.config')
local logger = require('src.core.logger')

local client = nil
local redis_cfg = nil
local reconnect_attempts = 0
local MAX_RECONNECT_ATTEMPTS = 10

-- Override hgetall to return key-value table instead of flat array
redis_lib.commands.hgetall = redis_lib.command('hgetall', {
    response = function(response)
        local result = {}
        for i = 1, #response, 2 do
            result[response[i]] = response[i + 1]
        end
        return result
    end
})

local function do_connect()
    if not redis_cfg then
        redis_cfg = config.redis_config()
    end
    local ok, err = pcall(function()
        client = redis_lib.connect({
            host = redis_cfg.host,
            port = redis_cfg.port
        })
    end)
    if not ok then
        return false, err
    end
    if redis_cfg.password and redis_cfg.password ~= '' then
        client:auth(redis_cfg.password)
    end
    if redis_cfg.db and redis_cfg.db ~= 0 then
        client:select(redis_cfg.db)
    end
    reconnect_attempts = 0
    return true
end

-- Automatic reconnection with exponential backoff
local function ensure_connected()
    if client then
        -- Quick ping check
        local ok = pcall(function() client:ping() end)
        if ok then return true end
        logger.warn('Redis connection lost, attempting reconnect...')
        client = nil
    end
    while reconnect_attempts < MAX_RECONNECT_ATTEMPTS do
        reconnect_attempts = reconnect_attempts + 1
        local backoff = math.min(2 ^ reconnect_attempts, 30)
        logger.info('Redis reconnect attempt %d/%d (backoff: %ds)', reconnect_attempts, MAX_RECONNECT_ATTEMPTS, backoff)
        local ok, err = do_connect()
        if ok then
            logger.info('Redis reconnected successfully')
            return true
        end
        logger.warn('Redis reconnect failed: %s', tostring(err))
        local socket = require('socket')
        socket.sleep(backoff)
    end
    logger.error('Redis reconnection failed after %d attempts', MAX_RECONNECT_ATTEMPTS)
    return false
end

-- Safe command wrapper with auto-reconnect
local function safe_call(method, ...)
    if not ensure_connected() then
        return nil
    end
    local ok, result = pcall(method, client, ...)
    if not ok then
        -- Connection may have dropped mid-call
        logger.warn('Redis command failed: %s — retrying after reconnect', tostring(result))
        client = nil
        if ensure_connected() then
            ok, result = pcall(method, client, ...)
            if ok then return result end
        end
        logger.error('Redis command failed after reconnect: %s', tostring(result))
        return nil
    end
    return result
end

function redis_mod.connect()
    redis_cfg = config.redis_config()
    local ok, err = do_connect()
    if not ok then
        logger.error('Failed to connect to Redis: %s', tostring(err))
        return false, err
    end
    logger.info('Connected to Redis at %s:%d (db %d)', redis_cfg.host, redis_cfg.port, redis_cfg.db or 0)
    return true
end

-- Get the raw redis client
function redis_mod.client()
    ensure_connected()
    return client
end

-- Proxy common operations with auto-reconnect
function redis_mod.get(key)
    return safe_call(client.get, key)
end

function redis_mod.set(key, value)
    return safe_call(client.set, key, value)
end

function redis_mod.setex(key, ttl, value)
    return safe_call(client.setex, key, ttl, value)
end

function redis_mod.setnx(key, value)
    return safe_call(client.setnx, key, value)
end

function redis_mod.del(key)
    return safe_call(client.del, key)
end

function redis_mod.exists(key)
    return safe_call(client.exists, key)
end

function redis_mod.expire(key, ttl)
    return safe_call(client.expire, key, ttl)
end

function redis_mod.incr(key)
    return safe_call(client.incr, key)
end

function redis_mod.incrby(key, amount)
    return safe_call(client.incrby, key, amount)
end

function redis_mod.hget(key, field)
    return safe_call(client.hget, key, field)
end

function redis_mod.hset(key, field, value)
    return safe_call(client.hset, key, field, value)
end

function redis_mod.hdel(key, field)
    return safe_call(client.hdel, key, field)
end

function redis_mod.hgetall(key)
    return safe_call(client.hgetall, key)
end

function redis_mod.hexists(key, field)
    return safe_call(client.hexists, key, field)
end

function redis_mod.hincrby(key, field, increment)
    return safe_call(client.hincrby, key, field, increment)
end

function redis_mod.sadd(key, value)
    return safe_call(client.sadd, key, value)
end

function redis_mod.srem(key, value)
    return safe_call(client.srem, key, value)
end

function redis_mod.sismember(key, value)
    return safe_call(client.sismember, key, value)
end

function redis_mod.smembers(key)
    return safe_call(client.smembers, key)
end

-- List operations (used by AI plugin)
function redis_mod.rpush(key, value)
    return safe_call(client.rpush, key, value)
end

function redis_mod.lrange(key, start, stop)
    return safe_call(client.lrange, key, start, stop)
end

function redis_mod.ltrim(key, start, stop)
    return safe_call(client.ltrim, key, start, stop)
end

-- SCAN-based iteration — replaces all KEYS usage
-- Returns all keys matching pattern without blocking
function redis_mod.scan(pattern)
    if not ensure_connected() then
        return {}
    end
    local results = {}
    local cursor = '0'
    repeat
        local ok, reply = pcall(function()
            return client:scan(cursor, { match = pattern, count = 100 })
        end)
        if not ok or not reply then break end
        cursor = reply[1]
        for _, key in ipairs(reply[2]) do
            table.insert(results, key)
        end
    until cursor == '0'
    return results
end

-- DEPRECATED: kept for compatibility but uses SCAN internally
function redis_mod.keys(pattern)
    logger.warn('redis.keys() called — prefer redis.scan() to avoid blocking')
    return redis_mod.scan(pattern)
end

-- Pipeline support: batch multiple commands and execute together
function redis_mod.pipeline(fn)
    if not ensure_connected() then
        return nil
    end
    local pipeline = client:pipeline()
    fn(pipeline)
    local ok, results = pcall(function()
        return pipeline:execute()
    end)
    if not ok then
        logger.error('Redis pipeline failed: %s', tostring(results))
        return nil
    end
    return results
end

function redis_mod.disconnect()
    if client then
        pcall(function() client:quit() end)
        client = nil
        logger.info('Disconnected from Redis')
    end
end

return redis_mod
