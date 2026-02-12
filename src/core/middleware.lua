--[[
    mattata v2.0 - Middleware Pipeline
    Runs an ordered chain of middleware functions before plugin dispatch.
    Each middleware receives (ctx, message) and returns (ctx, should_continue).
]]

local middleware = {}

local logger = require('src.core.logger')

local chain = {}

-- Register a middleware (order matters)
function middleware.use(mw)
    if type(mw) ~= 'table' or type(mw.run) ~= 'function' then
        logger.error('Invalid middleware: must be a table with a run(ctx, message) function')
        return
    end
    table.insert(chain, mw)
    logger.debug('Registered middleware: %s', mw.name or '(unnamed)')
end

-- Run the full middleware chain
-- Returns the modified ctx, and whether processing should continue
function middleware.run(ctx, message)
    for _, mw in ipairs(chain) do
        local ok, err = pcall(function()
            local new_ctx, should_continue = mw.run(ctx, message)
            if new_ctx then
                ctx = new_ctx
            end
            if should_continue == false then
                ctx._stopped = true
                ctx._stopped_by = mw.name
            end
        end)
        if not ok then
            logger.error('Middleware %s failed: %s', mw.name or '(unnamed)', tostring(err))
        end
        if ctx._stopped then
            return ctx, false
        end
    end
    return ctx, true
end

-- Reset chain (useful for testing)
function middleware.reset()
    chain = {}
end

-- Get count of registered middleware
function middleware.count()
    return #chain
end

return middleware
