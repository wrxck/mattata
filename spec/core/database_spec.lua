--[[
    Tests for src/core/database.lua
    Tests connection pooling, query execution, insert, upsert, and transactions.
    Uses mock_db to avoid real PostgreSQL connections.
]]

describe('core.database (mock)', function()
    local mock_db = require('spec.helpers.mock_db')
    local db

    before_each(function()
        db = mock_db.new()
    end)

    after_each(function()
        db.reset()
    end)

    describe('query()', function()
        it('should record SQL queries', function()
            db.query('SELECT 1')
            assert.are.equal(1, #db.queries)
            assert.are.equal('SELECT 1', db.queries[1].sql)
        end)

        it('should return empty table by default', function()
            local result = db.query('SELECT * FROM users')
            assert.are.same({}, result)
        end)

        it('should return configured next_result', function()
            local expected = { { user_id = 1, username = 'test' } }
            db.set_next_result(expected)
            local result = db.query('SELECT * FROM users')
            assert.are.same(expected, result)
        end)

        it('should consume next_result after one use', function()
            db.set_next_result({ { id = 1 } })
            db.query('SELECT 1')
            local result = db.query('SELECT 2')
            assert.are.same({}, result)
        end)

        it('should consume results from the queue in order', function()
            db.queue_result({ { id = 1 } })
            db.queue_result({ { id = 2 } })
            local r1 = db.query('SELECT 1')
            local r2 = db.query('SELECT 2')
            assert.are.equal(1, r1[1].id)
            assert.are.equal(2, r2[1].id)
        end)
    end)

    describe('execute()', function()
        it('should record parameterized queries', function()
            db.execute('SELECT * FROM users WHERE user_id = $1', { 12345 })
            assert.are.equal(1, #db.queries)
            assert.are.same({ 12345 }, db.queries[1].params)
        end)

        it('should return configured next_result', function()
            local expected = { { count = 5 } }
            db.set_next_result(expected)
            local result = db.execute('SELECT COUNT(*) FROM users', {})
            assert.are.same(expected, result)
        end)

        it('should record multiple execute calls', function()
            db.execute('INSERT INTO users (id) VALUES ($1)', { 1 })
            db.execute('INSERT INTO users (id) VALUES ($1)', { 2 })
            assert.are.equal(2, #db.queries)
        end)
    end)

    describe('insert()', function()
        it('should record the insert operation', function()
            db.insert('users', { user_id = 123, username = 'test' })
            assert.are.equal(1, #db.queries)
            assert.are.equal('insert', db.queries[1].op)
            assert.are.equal('users', db.queries[1].table_name)
            assert.are.equal(123, db.queries[1].data.user_id)
        end)

        it('should store data in the data table', function()
            db.insert('users', { user_id = 123 })
            assert.are.equal(1, #db.data['users'])
            assert.are.equal(123, db.data['users'][1].user_id)
        end)

        it('should return inserted row wrapped in table', function()
            local result = db.insert('users', { user_id = 123 })
            assert.are.equal(1, #result)
            assert.are.equal(123, result[1].user_id)
        end)

        it('should handle multiple inserts into same table', function()
            db.insert('users', { user_id = 1 })
            db.insert('users', { user_id = 2 })
            assert.are.equal(2, #db.data['users'])
        end)
    end)

    describe('upsert()', function()
        it('should record the upsert operation', function()
            db.upsert('users', { user_id = 123, username = 'test' }, { 'user_id' }, { 'username' })
            assert.are.equal(1, #db.queries)
            assert.are.equal('upsert', db.queries[1].op)
            assert.are.equal('users', db.queries[1].table_name)
        end)

        it('should store data in the data table', function()
            db.upsert('users', { user_id = 123, username = 'test' }, { 'user_id' }, { 'username' })
            assert.are.equal(1, #db.data['users'])
        end)

        it('should record conflict and update keys', function()
            db.upsert('users', { user_id = 123 }, { 'user_id' }, { 'username', 'last_seen' })
            assert.are.same({ 'user_id' }, db.queries[1].conflict_keys)
            assert.are.same({ 'username', 'last_seen' }, db.queries[1].update_keys)
        end)
    end)

    describe('transaction()', function()
        it('should call the provided function with query and execute', function()
            local called = false
            db.transaction(function(query, execute)
                called = true
                assert.is_function(query)
                assert.is_function(execute)
            end)
            assert.is_true(called)
        end)

        it('should return the result of the function', function()
            local result = db.transaction(function(query, execute)
                return 'success'
            end)
            assert.are.equal('success', result)
        end)
    end)

    describe('pool_stats()', function()
        it('should return available and max_size', function()
            local stats = db.pool_stats()
            assert.is_not_nil(stats.available)
            assert.is_not_nil(stats.max_size)
            assert.are.equal(5, stats.available)
            assert.are.equal(10, stats.max_size)
        end)
    end)

    describe('reset()', function()
        it('should clear all recorded state', function()
            db.insert('users', { user_id = 1 })
            db.execute('SELECT 1', {})
            db.set_next_result({ { id = 1 } })
            db.reset()
            assert.are.same({}, db.queries)
            assert.are.same({}, db.data)
            assert.is_nil(db.next_result)
        end)
    end)

    describe('has_query()', function()
        it('should return true when a matching query exists', function()
            db.execute('SELECT * FROM users WHERE user_id = $1', { 1 })
            assert.is_true(db.has_query('SELECT.*FROM users'))
        end)

        it('should return false when no matching query exists', function()
            db.execute('SELECT 1', {})
            assert.is_false(db.has_query('INSERT'))
        end)
    end)
end)
