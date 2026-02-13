--[[
    mattata v2.1 - Redis Connection Pool Module
    Redis is used as cache/session store only. PostgreSQL is the primary database.
    Implements connection pooling with copas semaphore guards,
    automatic reconnection with backoff, SCAN replacement for KEYS, and pipeline support.
]]

local redis_mod = {}

local redis_lib = require('redis')
local config = require('src.core.config')
local logger = require('src.core.logger')
local copas_sem = require('copas.semaphore')

local pool = {}
local pool_size = 5
local pool_semaphore = nil
local redis_cfg = nil

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

-- Create a single Redis connection
local function create_connection()
    if not redis_cfg then
        redis_cfg = config.redis_config()
    end
    local conn
    local ok, err = pcall(function()
        conn = redis_lib.connect({
            host = redis_cfg.host,
            port = redis_cfg.port
        })
    end)
    if not ok then
        return nil, err
    end
    if redis_cfg.password and redis_cfg.password ~= '' then
        conn:auth(redis_cfg.password)
    end
    if redis_cfg.db and redis_cfg.db ~= 0 then
        conn:select(redis_cfg.db)
    end
    return conn
end

-- Acquire a connection from the pool
local function acquire()
    -- Take a semaphore permit (blocks coroutine if pool exhausted)
    if pool_semaphore then
        local ok, err = pool_semaphore:take(1, 10)
        if not ok then
            logger.error('Redis pool semaphore timeout: %s', tostring(err))
            return nil, 'Redis pool exhausted'
        end
    end
    -- Return pooled connection (dead connections handled by safe_call retry)
    if #pool > 0 then
        return table.remove(pool)
    end
    -- Create fresh connection
    local conn, err = create_connection()
    if not conn then
        logger.error('Failed to create Redis connection: %s', tostring(err))
        if pool_semaphore then pool_semaphore:give(1) end
        return nil, err
    end
    return conn
end

-- Release a connection back to the pool
local function release(conn)
    if not conn then return end
    if #pool < pool_size then
        table.insert(pool, conn)
    else
        pcall(function() conn:quit() end)
    end
    if pool_semaphore then pool_semaphore:give(1) end
end

-- Discard a connection without returning it to the pool
local function discard(conn)
    if conn then
        pcall(function() conn:quit() end)
    end
    if pool_semaphore then pool_semaphore:give(1) end
end

-- Safe command wrapper with auto-reconnect
-- method_name is a string like 'get', 'set', etc.
local function safe_call(method_name, ...)
    local conn, err = acquire()
    if not conn then
        return nil
    end
    local ok, result = pcall(function(...)
        return conn[method_name](conn, ...)
    end, ...)
    if not ok then
        -- Connection may have dropped mid-call — discard and retry once
        logger.warn('Redis %s failed: %s — retrying after reconnect', method_name, tostring(result))
        discard(conn)
        conn, err = acquire()
        if not conn then
            logger.error('Redis reconnect failed: %s', tostring(err))
            return nil
        end
        ok, result = pcall(function(...)
            return conn[method_name](conn, ...)
        end, ...)
        if not ok then
            logger.error('Redis %s failed after reconnect: %s', method_name, tostring(result))
            discard(conn)
            return nil
        end
    end
    release(conn)
    return result
end

function redis_mod.connect()
    redis_cfg = config.redis_config()
    pool_size = config.get_number('REDIS_POOL_SIZE', 5)

    -- Create initial connection to validate credentials
    local conn, err = create_connection()
    if not conn then
        logger.error('Failed to connect to Redis: %s', tostring(err))
        return false, err
    end
    table.insert(pool, conn)

    -- Create semaphore to guard concurrent pool access
    -- max = pool_size, start = pool_size (all permits available), timeout = 10s
    pool_semaphore = copas_sem.new(pool_size, pool_size, 10)

    logger.info('Connected to Redis at %s:%d (db %d, pool size: %d)', redis_cfg.host, redis_cfg.port, redis_cfg.db or 0, pool_size)
    return true
end

-- Get the raw redis client (deprecated — prefer using proxy functions)
function redis_mod.client()
    logger.warn('redis.client() is deprecated — use redis proxy functions instead')
    local conn = acquire()
    return conn
end

-- Proxy common operations with auto-reconnect
function redis_mod.get(key)
    return safe_call('get', key)
end

function redis_mod.set(key, value)
    return safe_call('set', key, value)
end

function redis_mod.setex(key, ttl, value)
    return safe_call('setex', key, ttl, value)
end

function redis_mod.setnx(key, value)
    return safe_call('setnx', key, value)
end

function redis_mod.del(key)
    return safe_call('del', key)
end

function redis_mod.exists(key)
    return safe_call('exists', key)
end

function redis_mod.expire(key, ttl)
    return safe_call('expire', key, ttl)
end

function redis_mod.incr(key)
    return safe_call('incr', key)
end

function redis_mod.incrby(key, amount)
    return safe_call('incrby', key, amount)
end

function redis_mod.getset(key, value)
    return safe_call('getset', key, value)
end

function redis_mod.hget(key, field)
    return safe_call('hget', key, field)
end

function redis_mod.hset(key, field, value)
    return safe_call('hset', key, field, value)
end

function redis_mod.hdel(key, field)
    return safe_call('hdel', key, field)
end

function redis_mod.hgetall(key)
    return safe_call('hgetall', key)
end

function redis_mod.hexists(key, field)
    return safe_call('hexists', key, field)
end

function redis_mod.hincrby(key, field, increment)
    return safe_call('hincrby', key, field, increment)
end

function redis_mod.sadd(key, value)
    return safe_call('sadd', key, value)
end

function redis_mod.srem(key, value)
    return safe_call('srem', key, value)
end

function redis_mod.sismember(key, value)
    return safe_call('sismember', key, value)
end

function redis_mod.smembers(key)
    return safe_call('smembers', key)
end

-- List operations (used by AI plugin)
function redis_mod.rpush(key, value)
    return safe_call('rpush', key, value)
end

function redis_mod.lrange(key, start, stop)
    return safe_call('lrange', key, start, stop)
end

function redis_mod.ltrim(key, start, stop)
    return safe_call('ltrim', key, start, stop)
end

-- SCAN-based iteration — replaces all KEYS usage
-- Returns all keys matching pattern without blocking
function redis_mod.scan(pattern)
    local conn = acquire()
    if not conn then
        return {}
    end
    local results = {}
    local cursor = '0'
    repeat
        local ok, reply = pcall(function()
            return conn:scan(cursor, { match = pattern, count = 100 })
        end)
        if not ok or not reply then
            discard(conn)
            return results
        end
        cursor = reply[1]
        for _, key in ipairs(reply[2]) do
            table.insert(results, key)
        end
    until cursor == '0'
    release(conn)
    return results
end

-- DEPRECATED: kept for compatibility but uses SCAN internally
function redis_mod.keys(pattern)
    logger.warn('redis.keys() called — prefer redis.scan() to avoid blocking')
    return redis_mod.scan(pattern)
end

-- Pipeline support: batch multiple commands and execute together
function redis_mod.pipeline(fn)
    local conn = acquire()
    if not conn then
        return nil
    end
    local pipeline = conn:pipeline()
    fn(pipeline)
    local ok, results = pcall(function()
        return pipeline:execute()
    end)
    if not ok then
        logger.error('Redis pipeline failed: %s', tostring(results))
        discard(conn)
        return nil
    end
    release(conn)
    return results
end

function redis_mod.disconnect()
    for _, conn in ipairs(pool) do
        pcall(function() conn:quit() end)
    end
    pool = {}
    pool_semaphore = nil
    logger.info('Disconnected from Redis (pool drained)')
end

return redis_mod
