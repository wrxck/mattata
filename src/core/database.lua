--[[
    mattata v2.1 - PostgreSQL Database Module
    Uses pgmoon for async-compatible PostgreSQL connections.
    Implements connection pooling with copas semaphore guards,
    automatic reconnection, and transaction helpers.
]]

local database = {}

local pgmoon = require('pgmoon')
local config = require('src.core.config')
local logger = require('src.core.logger')
local copas_sem = require('copas.semaphore')

local pool = {}
local pool_size = 10
local pool_timeout = 30000
local pool_semaphore = nil
local db_config = nil

-- Initialise pool configuration
local function get_config()
    if not db_config then
        db_config = config.database()
    end
    return db_config
end

-- Create a new pgmoon connection
local function create_connection()
    local cfg = get_config()
    local pg = pgmoon.new({
        host = cfg.host,
        port = cfg.port,
        database = cfg.database,
        user = cfg.user,
        password = cfg.password
    })
    local ok, err = pg:connect()
    if not ok then
        return nil, err
    end
    pg:settimeout(pool_timeout)
    return pg
end

function database.connect()
    local cfg = get_config()
    pool_size = config.get_number('DATABASE_POOL_SIZE', 10)
    pool_timeout = config.get_number('DATABASE_TIMEOUT', 30000)

    -- Create initial connection to validate credentials
    local pg, err = create_connection()
    if not pg then
        logger.error('Failed to connect to PostgreSQL: %s', tostring(err))
        return false, err
    end
    table.insert(pool, pg)

    -- Create semaphore to guard concurrent pool access
    -- max = pool_size, start = pool_size (all permits available), timeout = 30s
    pool_semaphore = copas_sem.new(pool_size, pool_size, 30)

    logger.info('Connected to PostgreSQL at %s:%d/%s (pool size: %d)', cfg.host, cfg.port, cfg.database, pool_size)
    return true
end

-- Acquire a connection from the pool
function database.acquire()
    -- Take a semaphore permit (blocks coroutine if pool exhausted, 30s timeout)
    if pool_semaphore then
        local ok, err = pool_semaphore:take(1, 30)
        if not ok then
            logger.error('Failed to acquire pool permit: %s', tostring(err))
            return nil, 'Pool exhausted (semaphore timeout)'
        end
    end
    if #pool > 0 then
        return table.remove(pool)
    end
    -- Pool exhausted — create a new connection
    local pg, err = create_connection()
    if not pg then
        logger.error('Failed to create new connection: %s', tostring(err))
        -- Return the permit since we failed to use it
        if pool_semaphore then pool_semaphore:give(1) end
        return nil, err
    end
    return pg
end

-- Release a connection back to the pool
function database.release(pg)
    if not pg then return end
    if #pool < pool_size then
        table.insert(pool, pg)
    else
        pcall(function() pg:disconnect() end)
    end
    -- Return the semaphore permit
    if pool_semaphore then pool_semaphore:give(1) end
end

-- Execute a raw SQL query with automatic connection management
function database.query(sql, ...)
    local pg, err = database.acquire()
    if not pg then
        logger.error('Database not connected')
        return nil, 'Database not connected'
    end
    local result, query_err, _, _ = pg:query(sql)
    if not result then
        -- Check for connection loss and attempt reconnect
        if query_err and (query_err:match('closed') or query_err:match('broken') or query_err:match('timeout')) then
            logger.warn('Connection lost, attempting reconnect...')
            pcall(function() pg:disconnect() end)
            -- Release the dead connection's permit before reconnect
            if pool_semaphore then pool_semaphore:give(1) end
            pg, err = create_connection()
            if pg then
                -- Re-acquire a permit for the new connection
                if pool_semaphore then
                    local ok, sem_err = pool_semaphore:take(1, 30)
                    if not ok then
                        pcall(function() pg:disconnect() end)
                        logger.error('Reconnect semaphore acquire failed: %s', tostring(sem_err))
                        return nil, 'Pool exhausted during reconnect'
                    end
                end
                result, query_err = pg:query(sql)
                if result then
                    database.release(pg)
                    return result
                end
                database.release(pg)
            end
            logger.error('Reconnect failed for query: %s', tostring(query_err or err))
            return nil, query_err or err
        end
        logger.error('Query failed: %s\nSQL: %s', tostring(query_err), sql)
        database.release(pg)
        return nil, query_err
    end
    database.release(pg)
    return result
end

-- Execute a parameterized query (manually escape values)
function database.execute(sql, params)
    local pg, _ = database.acquire()
    if not pg then
        return nil, 'Database not connected'
    end
    if params then
        local escaped = {}
        for i, v in ipairs(params) do
            if v == nil then
                escaped[i] = 'NULL'
            elseif type(v) == 'number' then
                escaped[i] = tostring(v)
            elseif type(v) == 'boolean' then
                escaped[i] = v and 'TRUE' or 'FALSE'
            else
                escaped[i] = pg:escape_literal(tostring(v))
            end
        end
        -- Replace $1, $2, etc. with escaped values
        sql = sql:gsub('%$(%d+)', function(n)
            return escaped[tonumber(n)] or '$' .. n
        end)
    end
    local result, query_err = pg:query(sql)
    if not result then
        -- Attempt reconnect on connection failure
        if query_err and (query_err:match('closed') or query_err:match('broken') or query_err:match('timeout')) then
            logger.warn('Connection lost during execute, reconnecting...')
            pcall(function() pg:disconnect() end)
            -- Release the dead connection's permit before reconnect
            if pool_semaphore then pool_semaphore:give(1) end
            local new_pg
            new_pg, _ = create_connection()
            if new_pg then
                -- Re-acquire a permit for the new connection
                if pool_semaphore then
                    local ok, sem_err = pool_semaphore:take(1, 30)
                    if not ok then
                        pcall(function() new_pg:disconnect() end)
                        logger.error('Reconnect semaphore acquire failed: %s', tostring(sem_err))
                        return nil, 'Pool exhausted during reconnect'
                    end
                end
                result, query_err = new_pg:query(sql)
                if result then
                    database.release(new_pg)
                    return result
                end
                database.release(new_pg)
            end
        else
            database.release(pg)
        end
        logger.error('Query failed: %s\nSQL: %s', tostring(query_err), sql)
        return nil, query_err
    end
    database.release(pg)
    return result
end

-- Run a function inside a transaction (BEGIN / COMMIT / ROLLBACK)
function database.transaction(fn)
    local pg, _ = database.acquire()
    if not pg then
        return nil, 'Database not connected'
    end
    local ok, begin_err = pg:query('BEGIN')
    if not ok then
        database.release(pg)
        return nil, begin_err
    end
    -- Build a scoped query function for this connection
    local function scoped_query(sql)
        return pg:query(sql)
    end
    local function scoped_execute(sql, params)
        if params then
            local escaped = {}
            for i, v in ipairs(params) do
                if v == nil then
                    escaped[i] = 'NULL'
                elseif type(v) == 'number' then
                    escaped[i] = tostring(v)
                elseif type(v) == 'boolean' then
                    escaped[i] = v and 'TRUE' or 'FALSE'
                else
                    escaped[i] = pg:escape_literal(tostring(v))
                end
            end
            sql = sql:gsub('%$(%d+)', function(n)
                return escaped[tonumber(n)] or '$' .. n
            end)
        end
        return pg:query(sql)
    end
    local success, result = pcall(fn, scoped_query, scoped_execute)
    if success then
        pg:query('COMMIT')
        database.release(pg)
        return result
    else
        pg:query('ROLLBACK')
        database.release(pg)
        logger.error('Transaction failed: %s', tostring(result))
        return nil, result
    end
end

-- Convenience: insert and return the row
function database.insert(table_name, data)
    local columns = {}
    local values = {}
    local params = {}
    local i = 1
    for k, v in pairs(data) do
        table.insert(columns, k)
        table.insert(values, '$' .. i)
        table.insert(params, v)
        i = i + 1
    end
    local sql = string.format(
        'INSERT INTO %s (%s) VALUES (%s) RETURNING *',
        table_name,
        table.concat(columns, ', '),
        table.concat(values, ', ')
    )
    return database.execute(sql, params)
end

-- Convenience: upsert (INSERT ON CONFLICT UPDATE)
function database.upsert(table_name, data, conflict_keys, update_keys)
    local columns = {}
    local values = {}
    local params = {}
    local i = 1
    for k, v in pairs(data) do
        table.insert(columns, k)
        table.insert(values, '$' .. i)
        table.insert(params, v)
        i = i + 1
    end
    local updates = {}
    for _, k in ipairs(update_keys) do
        table.insert(updates, k .. ' = EXCLUDED.' .. k)
    end
    local sql = string.format(
        'INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s RETURNING *',
        table_name,
        table.concat(columns, ', '),
        table.concat(values, ', '),
        table.concat(conflict_keys, ', '),
        table.concat(updates, ', ')
    )
    return database.execute(sql, params)
end

-- call a stored procedure: SELECT * FROM func_name(arg1, arg2, ...)
-- func_name is validated to contain only safe characters (alphanumeric + underscore)
-- nil values are inlined as NULL; non-nil values are escaped inline
function database.call(func_name, params, nparams)
    if not func_name:match('^[%w_]+$') then
        logger.error('Invalid stored procedure name: %s', func_name)
        return nil, 'Invalid stored procedure name'
    end
    params = params or {}
    nparams = nparams or params.n or #params
    local pg, acquire_err = database.acquire()
    if not pg then
        return nil, acquire_err or 'Database not connected'
    end
    local args = {}
    for i = 1, nparams do
        local v = params[i]
        if v == nil then
            args[i] = 'NULL'
        elseif type(v) == 'number' then
            args[i] = tostring(v)
        elseif type(v) == 'boolean' then
            args[i] = v and 'TRUE' or 'FALSE'
        else
            args[i] = pg:escape_literal(tostring(v))
        end
    end
    local sql = string.format(
        'SELECT * FROM %s(%s)',
        func_name,
        table.concat(args, ', ')
    )
    local result, query_err = pg:query(sql)
    if not result then
        logger.error('Query failed: %s\nSQL: %s', tostring(query_err), sql)
        database.release(pg)
        return nil, query_err
    end
    database.release(pg)
    return result
end

-- get the raw pgmoon connection for advanced usage
function database.connection()
    return database.acquire()
end

-- Get current pool stats
function database.pool_stats()
    return {
        available = #pool,
        max_size = pool_size
    }
end

function database.disconnect()
    for _, pg in ipairs(pool) do
        pcall(function() pg:disconnect() end)
    end
    pool = {}
    pool_semaphore = nil
    logger.info('Disconnected from PostgreSQL (pool drained)')
end

return database
