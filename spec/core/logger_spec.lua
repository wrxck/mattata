--[[
    Tests for src/core/logger.lua
    Tests log levels, formatting, and level filtering.
]]

describe('core.logger', function()
    local logger
    local captured_output

    before_each(function()
        package.loaded['src.core.logger'] = nil
        package.loaded['src.core.config'] = {
            debug = function() return false end,
            is_enabled = function() return false end,
            get = function(key, default) return default end,
            load = function() end,
            VERSION = '2.0',
        }
        logger = require('src.core.logger')
        captured_output = {}

        -- Override io.write to capture output
        local original_write = io.write
        io.write = function(s)
            table.insert(captured_output, s)
        end
    end)

    after_each(function()
        -- Restore io.write (best effort, may already be restored)
        io.write = _G._original_io_write or io.write
    end)

    -- Save original io.write before all tests
    setup(function()
        _G._original_io_write = io.write
    end)

    teardown(function()
        io.write = _G._original_io_write
    end)

    describe('set_level()', function()
        it('should accept valid level strings', function()
            assert.has_no.errors(function()
                logger.set_level('DEBUG')
                logger.set_level('INFO')
                logger.set_level('WARN')
                logger.set_level('ERROR')
            end)
        end)

        it('should be case-insensitive', function()
            assert.has_no.errors(function()
                logger.set_level('debug')
                logger.set_level('info')
                logger.set_level('warn')
                logger.set_level('error')
            end)
        end)

        it('should silently ignore invalid levels', function()
            assert.has_no.errors(function()
                logger.set_level('INVALID')
            end)
        end)
    end)

    describe('log level filtering', function()
        it('should output ERROR when level is ERROR', function()
            logger.set_level('ERROR')
            logger.error('test error')
            assert.is_true(#captured_output > 0)
        end)

        it('should not output DEBUG when level is INFO', function()
            logger.set_level('INFO')
            logger.debug('should not appear')
            assert.are.equal(0, #captured_output)
        end)

        it('should not output INFO when level is WARN', function()
            logger.set_level('WARN')
            logger.info('should not appear')
            assert.are.equal(0, #captured_output)
        end)

        it('should not output WARN when level is ERROR', function()
            logger.set_level('ERROR')
            logger.warn('should not appear')
            assert.are.equal(0, #captured_output)
        end)

        it('should output DEBUG when level is DEBUG', function()
            logger.set_level('DEBUG')
            logger.debug('debug message')
            assert.is_true(#captured_output > 0)
        end)

        it('should output INFO when level is DEBUG', function()
            logger.set_level('DEBUG')
            logger.info('info message')
            assert.is_true(#captured_output > 0)
        end)

        it('should output WARN when level is INFO', function()
            logger.set_level('INFO')
            logger.warn('warn message')
            assert.is_true(#captured_output > 0)
        end)

        it('should output ERROR at any level', function()
            logger.set_level('DEBUG')
            logger.error('error message')
            assert.is_true(#captured_output > 0)
        end)
    end)

    describe('message formatting', function()
        it('should include level in output', function()
            logger.set_level('DEBUG')
            logger.error('test')
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('ERROR'))
        end)

        it('should include timestamp in output', function()
            logger.set_level('DEBUG')
            logger.info('test')
            local output = table.concat(captured_output)
            -- Check for date pattern like YYYY-MM-DD
            assert.is_truthy(output:match('%d%d%d%d%-%d%d%-%d%d'))
        end)

        it('should include the message text', function()
            logger.set_level('DEBUG')
            logger.info('hello world')
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('hello world'))
        end)

        it('should format with string.format when args provided', function()
            logger.set_level('DEBUG')
            logger.info('user %s has %d messages', 'Alice', 42)
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('user Alice has 42 messages'))
        end)

        it('should handle plain message without format args', function()
            logger.set_level('DEBUG')
            logger.info('simple message')
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('simple message'))
        end)

        it('should handle numeric message', function()
            logger.set_level('DEBUG')
            logger.info(42)
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('42'))
        end)

        it('should end with newline', function()
            logger.set_level('DEBUG')
            logger.info('test')
            local output = table.concat(captured_output)
            assert.is_truthy(output:match('\n$'))
        end)
    end)

    describe('init()', function()
        it('should set DEBUG level when config.debug() is true', function()
            package.loaded['src.core.logger'] = nil
            package.loaded['src.core.config'] = {
                debug = function() return true end,
                is_enabled = function() return true end,
                get = function(key, default) return default end,
                load = function() end,
                VERSION = '2.0',
            }
            logger = require('src.core.logger')
            captured_output = {}
            logger.init()
            logger.debug('should appear now')
            assert.is_true(#captured_output > 0)
        end)
    end)

    describe('different log levels produce different prefixes', function()
        before_each(function()
            logger.set_level('DEBUG')
        end)

        it('debug should include DEBUG', function()
            logger.debug('msg')
            assert.is_truthy(table.concat(captured_output):match('DEBUG'))
        end)

        it('info should include INFO', function()
            logger.info('msg')
            assert.is_truthy(table.concat(captured_output):match('INFO'))
        end)

        it('warn should include WARN', function()
            logger.warn('msg')
            assert.is_truthy(table.concat(captured_output):match('WARN'))
        end)

        it('error should include ERROR', function()
            logger.error('msg')
            assert.is_truthy(table.concat(captured_output):match('ERROR'))
        end)
    end)
end)
