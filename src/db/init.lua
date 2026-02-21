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
    { name = '004_performance_indexes', path = 'src.db.migrations.004_performance_indexes' },
    { name = '005_stored_procedures', path = 'src.db.migrations.005_stored_procedures' },
    { name = '006_import_procedures', path = 'src.db.migrations.006_import_procedures' },
    { name = '007_v1_import_tracking', path = 'src.db.migrations.007_v1_import_tracking' }
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
                -- Split on semicolons, respecting $$-delimited blocks
                local statements = {}
                local current = ''
                local in_dollar = false
                local i = 1
                while i <= #sql do
                    if sql:sub(i, i + 1) == '$$' then
                        in_dollar = not in_dollar
                        current = current .. '$$'
                        i = i + 2
                    elseif sql:sub(i, i) == ';' and not in_dollar then
                        local trimmed = current:match('^%s*(.-)%s*$')
                        if trimmed ~= '' then
                            statements[#statements + 1] = trimmed
                        end
                        current = ''
                        i = i + 1
                    else
                        current = current .. sql:sub(i, i)
                        i = i + 1
                    end
                end
                local trimmed = current:match('^%s*(.-)%s*$')
                if trimmed ~= '' then
                    statements[#statements + 1] = trimmed
                end
                for _, statement in ipairs(statements) do
                    local result, err = db.query(statement)
                    if not result and err then
                        migration_ok = false
                        migration_err = err
                        break
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
