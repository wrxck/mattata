--[[
    mattata v2.0 - Mock PostgreSQL Database
    Records queries and returns configurable results for testing.
]]

local mock_db = {}

function mock_db.new()
    local db = {
        queries = {},
        data = {},      -- table_name -> array of rows
        next_result = nil,
        result_queue = {},  -- FIFO queue of results to return
    }

    function db.query(sql)
        table.insert(db.queries, { sql = sql })
        if db.next_result then
            local r = db.next_result
            db.next_result = nil
            return r
        end
        if #db.result_queue > 0 then
            return table.remove(db.result_queue, 1)
        end
        return {}
    end

    function db.execute(sql, params)
        table.insert(db.queries, { sql = sql, params = params })
        if db.next_result then
            local r = db.next_result
            db.next_result = nil
            return r
        end
        if #db.result_queue > 0 then
            return table.remove(db.result_queue, 1)
        end
        return {}
    end

    function db.insert(table_name, data_row)
        table.insert(db.queries, { op = 'insert', table_name = table_name, data = data_row })
        if not db.data[table_name] then db.data[table_name] = {} end
        table.insert(db.data[table_name], data_row)
        if db.next_result then
            local r = db.next_result
            db.next_result = nil
            return r
        end
        return { data_row }
    end

    function db.upsert(table_name, data_row, conflict_keys, update_keys)
        table.insert(db.queries, { op = 'upsert', table_name = table_name, data = data_row, conflict_keys = conflict_keys, update_keys = update_keys })
        if not db.data[table_name] then db.data[table_name] = {} end
        table.insert(db.data[table_name], data_row)
        if db.next_result then
            local r = db.next_result
            db.next_result = nil
            return r
        end
        return { data_row }
    end

    -- Stored procedure call: records func_name, params, and a synthetic sql for has_query
    function db.call(func_name, params)
        local sql = 'SELECT * FROM ' .. func_name .. '(...)'
        table.insert(db.queries, { op = 'call', func_name = func_name, params = params, sql = sql })
        if db.next_result then
            local r = db.next_result
            db.next_result = nil
            return r
        end
        if #db.result_queue > 0 then
            return table.remove(db.result_queue, 1)
        end
        return {}
    end

    function db.set_next_result(result)
        db.next_result = result
    end

    -- Queue multiple results (consumed in order)
    function db.queue_result(result)
        table.insert(db.result_queue, result)
    end

    function db.transaction(fn)
        return fn(db.query, db.execute)
    end

    function db.pool_stats()
        return { available = 5, max_size = 10 }
    end

    function db.reset()
        db.queries = {}
        db.data = {}
        db.next_result = nil
        db.result_queue = {}
    end

    -- Helper: check if a query matching pattern was executed
    function db.has_query(pattern)
        for _, q in ipairs(db.queries) do
            if q.sql and q.sql:match(pattern) then
                return true
            end
        end
        return false
    end

    -- Helper: get the last query
    function db.last_query()
        return db.queries[#db.queries]
    end

    return db
end

return mock_db
