--[[
    Tests for src/core/middleware.lua
    Tests the middleware pipeline: use, run, reset, ordering, stopping.
]]

describe('core.middleware', function()
    local middleware

    before_each(function()
        -- Reset module and logger dependency
        package.loaded['src.core.middleware'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }
        middleware = require('src.core.middleware')
        middleware.reset()
    end)

    after_each(function()
        middleware.reset()
    end)

    describe('use()', function()
        it('should register a valid middleware', function()
            middleware.use({
                name = 'test',
                run = function(ctx, msg) return ctx, true end
            })
            assert.are.equal(1, middleware.count())
        end)

        it('should register multiple middleware', function()
            middleware.use({ name = 'a', run = function(ctx, msg) return ctx, true end })
            middleware.use({ name = 'b', run = function(ctx, msg) return ctx, true end })
            middleware.use({ name = 'c', run = function(ctx, msg) return ctx, true end })
            assert.are.equal(3, middleware.count())
        end)

        it('should reject middleware without run function', function()
            middleware.use({ name = 'bad' })
            assert.are.equal(0, middleware.count())
        end)

        it('should reject non-table middleware', function()
            middleware.use('not_a_table')
            assert.are.equal(0, middleware.count())
        end)

        it('should reject nil middleware', function()
            middleware.use(nil)
            assert.are.equal(0, middleware.count())
        end)

        it('should reject middleware with non-function run', function()
            middleware.use({ name = 'bad', run = 'not_a_function' })
            assert.are.equal(0, middleware.count())
        end)
    end)

    describe('run()', function()
        it('should run all middleware in order', function()
            local order = {}
            middleware.use({
                name = 'first',
                run = function(ctx, msg)
                    table.insert(order, 'first')
                    return ctx, true
                end
            })
            middleware.use({
                name = 'second',
                run = function(ctx, msg)
                    table.insert(order, 'second')
                    return ctx, true
                end
            })
            middleware.use({
                name = 'third',
                run = function(ctx, msg)
                    table.insert(order, 'third')
                    return ctx, true
                end
            })
            middleware.run({}, {})
            assert.are.same({ 'first', 'second', 'third' }, order)
        end)

        it('should return modified ctx', function()
            middleware.use({
                name = 'modifier',
                run = function(ctx, msg)
                    ctx.custom_field = 'hello'
                    return ctx, true
                end
            })
            local ctx, should_continue = middleware.run({}, {})
            assert.are.equal('hello', ctx.custom_field)
            assert.is_true(should_continue)
        end)

        it('should stop chain when middleware returns false', function()
            local ran_second = false
            middleware.use({
                name = 'blocker',
                run = function(ctx, msg)
                    return ctx, false
                end
            })
            middleware.use({
                name = 'never_runs',
                run = function(ctx, msg)
                    ran_second = true
                    return ctx, true
                end
            })
            local ctx, should_continue = middleware.run({}, {})
            assert.is_false(should_continue)
            assert.is_false(ran_second)
        end)

        it('should record which middleware stopped the chain', function()
            middleware.use({
                name = 'stopper',
                run = function(ctx, msg) return ctx, false end
            })
            local ctx = middleware.run({}, {})
            assert.is_true(ctx._stopped)
            assert.are.equal('stopper', ctx._stopped_by)
        end)

        it('should propagate ctx modifications between middleware', function()
            middleware.use({
                name = 'adder',
                run = function(ctx, msg)
                    ctx.step1 = true
                    return ctx, true
                end
            })
            middleware.use({
                name = 'reader',
                run = function(ctx, msg)
                    ctx.step2_saw_step1 = ctx.step1
                    return ctx, true
                end
            })
            local ctx = middleware.run({}, {})
            assert.is_true(ctx.step1)
            assert.is_true(ctx.step2_saw_step1)
        end)

        it('should continue if middleware errors', function()
            local ran_second = false
            middleware.use({
                name = 'erroring',
                run = function(ctx, msg)
                    error('something broke')
                    return ctx, true
                end
            })
            middleware.use({
                name = 'continues',
                run = function(ctx, msg)
                    ran_second = true
                    return ctx, true
                end
            })
            local ctx, should_continue = middleware.run({}, {})
            assert.is_true(ran_second)
            assert.is_true(should_continue)
        end)

        it('should handle middleware returning nil ctx gracefully', function()
            middleware.use({
                name = 'nil_returner',
                run = function(ctx, msg)
                    return nil, true
                end
            })
            middleware.use({
                name = 'post',
                run = function(ctx, msg)
                    ctx.post_ran = true
                    return ctx, true
                end
            })
            local ctx, should_continue = middleware.run({ initial = true }, {})
            assert.is_true(should_continue)
            -- ctx should be the original since nil was returned
            assert.is_true(ctx.initial)
        end)

        it('should return ctx, true when no middleware registered', function()
            local ctx, should_continue = middleware.run({ empty = true }, {})
            assert.is_true(should_continue)
            assert.is_true(ctx.empty)
        end)
    end)

    describe('reset()', function()
        it('should clear all registered middleware', function()
            middleware.use({ name = 'a', run = function(ctx, msg) return ctx, true end })
            middleware.use({ name = 'b', run = function(ctx, msg) return ctx, true end })
            assert.are.equal(2, middleware.count())
            middleware.reset()
            assert.are.equal(0, middleware.count())
        end)
    end)

    describe('count()', function()
        it('should return 0 when empty', function()
            assert.are.equal(0, middleware.count())
        end)

        it('should return correct count after registration', function()
            middleware.use({ name = 'a', run = function() return {}, true end })
            assert.are.equal(1, middleware.count())
        end)
    end)
end)
