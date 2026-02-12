--[[
    mattata v2.0 - Migration Runner
    Runs pending SQL migrations in order, wrapped in transactions.
    Supports migrations from src/db/migrations/ AND plugin.migration fields.
]]

local migrations = {}

local logger = require('src.core.logger')

local migration_files = {
    { name = '001_initial_schema', path = 'src.db.migrations.001_initial_schema' },
    { name = '002_federation_tables', path = 'src.db.migrations.002_federation_tables' },
    { name = '003_statistics_tables', path = 'src.db.migrations.003_statistics_tables' },
    { name = '004_performance_indexes', path = 'src.db.migrations.004_performance_indexes' }
}

function migrations.run(db)
    -- Create migrations tracking table
    db.query([[
        CREATE TABLE IF NOT EXISTS schema_migrations (
            name VARCHAR(255) PRIMARY KEY,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
    ]])

    -- Run each migration if not already applied
    for _, mig in ipairs(migration_files) do
        local applied = db.execute(
            'SELECT 1 FROM schema_migrations WHERE name = $1',
            { mig.name }
        )
        if not applied or #applied == 0 then
            logger.info('Running migration: %s', mig.name)
            local ok, mod = pcall(require, mig.path)
            if ok and type(mod) == 'table' and mod.up then
                -- Wrap migration in a transaction
                local begin_ok, begin_err = db.query('BEGIN')
                if not begin_ok and begin_err then
                    logger.error('Failed to begin transaction for migration %s: %s', mig.name, tostring(begin_err))
                    os.exit(1)
                end

                local sql = mod.up()
                local migration_ok = true
                local migration_err = nil
                -- Split on semicolons and execute each statement
                for statement in sql:gmatch('[^;]+') do
                    statement = statement:match('^%s*(.-)%s*$')
                    if statement ~= '' then
                        local result, err = db.query(statement)
                        if not result and err then
                            migration_ok = false
                            migration_err = err
                            break
                        end
                    end
                end

                if not migration_ok then
                    logger.error('Migration %s failed: %s — rolling back', mig.name, tostring(migration_err))
                    db.query('ROLLBACK')
                    os.exit(1)
                end

                -- Record migration as applied using parameterized query
                db.execute(
                    'INSERT INTO schema_migrations (name) VALUES ($1)',
                    { mig.name }
                )
                db.query('COMMIT')
                logger.info('Migration %s applied successfully', mig.name)
            else
                logger.error('Failed to load migration %s: %s', mig.name, tostring(mod))
                os.exit(1)
            end
        else
            logger.debug('Migration %s already applied', mig.name)
        end
    end

    logger.info('All migrations up to date')
end

return migrations
