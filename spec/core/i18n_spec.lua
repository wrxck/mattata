--[[
    Tests for src/core/i18n.lua
    Tests language loading, get, exists, translate with interpolation.
]]

describe('core.i18n', function()
    local i18n

    -- Mock language tables
    local mock_en_gb = {
        errors = {
            connection = 'Connection error.',
            admin = 'You need to be an admin.',
        },
        ban = {
            success = '{admin} has banned {target}.',
            specify = 'Please specify the user to ban.',
        },
        help = {
            greeting = 'Hey {name}!',
        },
    }

    local mock_de_de = {
        errors = {
            connection = 'Verbindungsfehler.',
            admin = 'Du musst ein Admin sein.',
        },
        ban = {
            success = '{admin} hat {target} gebannt.',
        },
    }

    before_each(function()
        package.loaded['src.core.i18n'] = nil
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            is_enabled = function() return false end,
            load = function() end,
            debug = function() return false end,
            VERSION = '2.0',
        }
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }

        -- Mock the language registry and language files
        package.loaded['src.languages.init'] = {
            en_gb = 'src.languages.en_gb',
            de_de = 'src.languages.de_de',
        }
        package.loaded['src.languages.en_gb'] = mock_en_gb
        package.loaded['src.languages.de_de'] = mock_de_de

        i18n = require('src.core.i18n')
        i18n.init()
    end)

    describe('init()', function()
        it('should load languages from the registry', function()
            assert.is_true(i18n.count() > 0)
        end)

        it('should load exactly the number of languages in the registry', function()
            assert.are.equal(2, i18n.count())
        end)
    end)

    describe('get()', function()
        it('should return a language table by code', function()
            local lang = i18n.get('en_gb')
            assert.is_not_nil(lang)
            assert.are.equal('Connection error.', lang.errors.connection)
        end)

        it('should return German language', function()
            local lang = i18n.get('de_de')
            assert.is_not_nil(lang)
            assert.are.equal('Verbindungsfehler.', lang.errors.connection)
        end)

        it('should fall back to en_gb for unknown code', function()
            local lang = i18n.get('zz_zz')
            assert.is_not_nil(lang)
            assert.are.equal('Connection error.', lang.errors.connection)
        end)

        it('should fall back to en_gb for nil code', function()
            local lang = i18n.get(nil)
            assert.is_not_nil(lang)
            assert.are.equal('Connection error.', lang.errors.connection)
        end)
    end)

    describe('exists()', function()
        it('should return true for loaded languages', function()
            assert.is_true(i18n.exists('en_gb'))
            assert.is_true(i18n.exists('de_de'))
        end)

        it('should return false for unloaded languages', function()
            assert.is_false(i18n.exists('zz_zz'))
            assert.is_false(i18n.exists('fr_fr'))
        end)
    end)

    describe('available()', function()
        it('should return sorted list of codes', function()
            local codes = i18n.available()
            assert.are.equal(2, #codes)
            -- Sorted alphabetically
            assert.are.equal('de_de', codes[1])
            assert.are.equal('en_gb', codes[2])
        end)
    end)

    describe('count()', function()
        it('should return the number of loaded languages', function()
            assert.are.equal(2, i18n.count())
        end)
    end)

    describe('t() - translation', function()
        it('should traverse nested keys', function()
            local result = i18n.t(mock_en_gb, 'errors', 'connection')
            assert.are.equal('Connection error.', result)
        end)

        it('should return nil for missing key', function()
            local result = i18n.t(mock_en_gb, 'nonexistent', 'key')
            assert.is_nil(result)
        end)

        it('should return nil for partially missing key', function()
            local result = i18n.t(mock_en_gb, 'errors', 'nonexistent')
            assert.is_nil(result)
        end)

        it('should interpolate variables', function()
            local result = i18n.t(mock_en_gb, 'ban', 'success', { admin = 'Alice', target = 'Bob' })
            assert.are.equal('Alice has banned Bob.', result)
        end)

        it('should handle multiple interpolation variables', function()
            local result = i18n.t(mock_en_gb, 'help', 'greeting', { name = 'Matt' })
            assert.are.equal('Hey Matt!', result)
        end)

        it('should accept language code string as first arg', function()
            local result = i18n.t('en_gb', 'errors', 'connection')
            assert.are.equal('Connection error.', result)
        end)

        it('should fall back to default lang for unknown code string', function()
            local result = i18n.t('zz_zz', 'errors', 'connection')
            assert.are.equal('Connection error.', result)
        end)

        it('should return nil when value is a table not a string', function()
            local result = i18n.t(mock_en_gb, 'errors')
            assert.is_nil(result)
        end)

        it('should handle nil lang_table by falling back', function()
            local result = i18n.t(nil, 'errors', 'connection')
            assert.are.equal('Connection error.', result)
        end)

        it('should return simple string without interpolation', function()
            local result = i18n.t(mock_en_gb, 'ban', 'specify')
            assert.are.equal('Please specify the user to ban.', result)
        end)
    end)
end)
