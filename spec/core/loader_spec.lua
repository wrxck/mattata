--[[
    Tests for src/core/loader.lua
    Tests plugin registration, command lookup, category lookup, is_permanent, reload.
    Uses mock plugins to avoid loading real plugin files.
]]

describe('core.loader', function()
    local loader

    -- Fake plugins for testing
    local fake_ping = {
        name = 'ping',
        category = 'utility',
        commands = { 'ping', 'pong' },
        help = '/ping - PONG!',
        description = 'Check bot responsiveness',
        on_message = function() end,
    }

    local fake_help = {
        name = 'help',
        category = 'utility',
        commands = { 'help', 'start' },
        help = '/help [command]',
        description = 'View help',
        permanent = true,
        on_message = function() end,
    }

    local fake_ban = {
        name = 'ban',
        category = 'admin',
        commands = { 'ban', 'b' },
        help = '/ban [user]',
        description = 'Ban users',
        admin_only = true,
        group_only = true,
        on_message = function() end,
    }

    local fake_about = {
        name = 'about',
        category = 'utility',
        commands = { 'about' },
        help = '/about',
        description = 'About the bot',
        on_message = function() end,
    }

    local fake_plugins = {
        name = 'plugins',
        category = 'utility',
        commands = { 'plugins' },
        help = '/plugins',
        description = 'Enable/disable plugins',
        on_message = function() end,
    }

    before_each(function()
        -- Reset all module caches
        package.loaded['src.core.loader'] = nil
        package.loaded['src.core.logger'] = {
            debug = function() end,
            info = function() end,
            warn = function() end,
            error = function() end,
        }
        package.loaded['src.core.config'] = {
            get = function(key, default) return default end,
            get_number = function(key, default) return default end,
            is_enabled = function() return false end,
            bot_admins = function() return {} end,
            load = function() end,
            VERSION = '2.0',
        }

        -- Mock category manifests
        package.loaded['src.plugins.admin.init'] = { plugins = { 'ban' } }
        package.loaded['src.plugins.utility.init'] = { plugins = { 'help', 'ping', 'about', 'plugins' } }
        package.loaded['src.plugins.fun.init'] = { plugins = {} }
        package.loaded['src.plugins.media.init'] = { plugins = {} }
        package.loaded['src.plugins.ai.init'] = { plugins = {} }

        -- Mock individual plugins
        package.loaded['src.plugins.admin.ban'] = fake_ban
        package.loaded['src.plugins.utility.help'] = fake_help
        package.loaded['src.plugins.utility.ping'] = fake_ping
        package.loaded['src.plugins.utility.about'] = fake_about
        package.loaded['src.plugins.utility.plugins'] = fake_plugins

        loader = require('src.core.loader')
        loader.init(nil, nil, nil)
    end)

    describe('init()', function()
        it('should load plugins from manifests', function()
            assert.is_true(loader.count() > 0)
        end)

        it('should load the expected number of plugins', function()
            assert.are.equal(5, loader.count())
        end)
    end)

    describe('get_plugins()', function()
        it('should return all loaded plugins', function()
            local plugins = loader.get_plugins()
            assert.are.equal(5, #plugins)
        end)

        it('should return plugins in order', function()
            local plugins = loader.get_plugins()
            -- Admin category loads first, then utility
            assert.are.equal('ban', plugins[1].name)
            assert.are.equal('help', plugins[2].name)
        end)
    end)

    describe('get_by_command()', function()
        it('should find plugin by primary command', function()
            local plugin = loader.get_by_command('ping')
            assert.is_not_nil(plugin)
            assert.are.equal('ping', plugin.name)
        end)

        it('should find plugin by alias command', function()
            local plugin = loader.get_by_command('pong')
            assert.is_not_nil(plugin)
            assert.are.equal('ping', plugin.name)
        end)

        it('should find plugin by short alias', function()
            local plugin = loader.get_by_command('b')
            assert.is_not_nil(plugin)
            assert.are.equal('ban', plugin.name)
        end)

        it('should be case-insensitive', function()
            local plugin = loader.get_by_command('PING')
            assert.is_not_nil(plugin)
            assert.are.equal('ping', plugin.name)
        end)

        it('should return nil for unknown command', function()
            local plugin = loader.get_by_command('nonexistent')
            assert.is_nil(plugin)
        end)
    end)

    describe('get_by_name()', function()
        it('should find plugin by name', function()
            local plugin = loader.get_by_name('ban')
            assert.is_not_nil(plugin)
            assert.are.equal('ban', plugin.name)
        end)

        it('should return nil for unknown name', function()
            local plugin = loader.get_by_name('nonexistent')
            assert.is_nil(plugin)
        end)
    end)

    describe('get_category()', function()
        it('should return all plugins in admin category', function()
            local plugins = loader.get_category('admin')
            assert.are.equal(1, #plugins)
            assert.are.equal('ban', plugins[1].name)
        end)

        it('should return all plugins in utility category', function()
            local plugins = loader.get_category('utility')
            assert.are.equal(4, #plugins)
        end)

        it('should return empty table for empty category', function()
            local plugins = loader.get_category('fun')
            assert.are.same({}, plugins)
        end)

        it('should return empty table for unknown category', function()
            local plugins = loader.get_category('nonexistent')
            assert.are.same({}, plugins)
        end)
    end)

    describe('is_permanent()', function()
        it('should return true for help plugin', function()
            assert.is_true(loader.is_permanent('help'))
        end)

        it('should return true for about plugin', function()
            assert.is_true(loader.is_permanent('about'))
        end)

        it('should return true for plugins plugin', function()
            assert.is_true(loader.is_permanent('plugins'))
        end)

        it('should return false for ban plugin', function()
            assert.is_false(loader.is_permanent('ban'))
        end)

        it('should return false for ping plugin', function()
            assert.is_false(loader.is_permanent('ping'))
        end)

        it('should return false for unknown plugin', function()
            assert.is_false(loader.is_permanent('nonexistent'))
        end)
    end)

    describe('reload()', function()
        it('should return false for non-existent plugin', function()
            local ok, err = loader.reload('nonexistent')
            assert.is_false(ok)
            assert.is_truthy(err:match('not found'))
        end)

        it('should successfully reload an existing plugin', function()
            -- Set up a new version of the plugin in package.loaded
            local new_ping = {
                name = 'ping',
                category = 'utility',
                commands = { 'ping', 'pong', 'latency' },
                help = '/ping - Updated!',
                description = 'Updated ping',
                on_message = function() return 'updated' end,
            }
            package.loaded['src.plugins.utility.ping'] = new_ping

            local ok = loader.reload('ping')
            assert.is_true(ok)

            -- New command should be registered
            local p = loader.get_by_command('latency')
            assert.is_not_nil(p)
            assert.are.equal('ping', p.name)
        end)

        it('should re-index commands after reload', function()
            -- Simulate reload with different commands
            local new_ping = {
                name = 'ping',
                commands = { 'newping' },
                on_message = function() end,
            }
            package.loaded['src.plugins.utility.ping'] = new_ping

            loader.reload('ping')

            -- Old commands should no longer work
            assert.is_nil(loader.get_by_command('pong'))
            -- New command should work
            assert.is_not_nil(loader.get_by_command('newping'))
        end)
    end)

    describe('get_help()', function()
        it('should return help for all plugins', function()
            local help = loader.get_help()
            assert.is_true(#help > 0)
        end)

        it('should return help for a specific category', function()
            local help = loader.get_help('admin')
            assert.are.equal(1, #help)
            assert.are.equal('ban', help[1].name)
        end)

        it('should include commands in help entries', function()
            local help = loader.get_help('utility')
            local found_ping = false
            for _, h in ipairs(help) do
                if h.name == 'ping' then
                    found_ping = true
                    assert.are.same({ 'ping', 'pong' }, h.commands)
                end
            end
            assert.is_true(found_ping)
        end)

        it('should include description in help entries', function()
            local help = loader.get_help('utility')
            for _, h in ipairs(help) do
                if h.name == 'ping' then
                    assert.are.equal('Check bot responsiveness', h.description)
                end
            end
        end)
    end)

    describe('get_categories()', function()
        it('should return list of all categories', function()
            local cats = loader.get_categories()
            assert.is_true(#cats > 0)
            -- Check it contains expected categories
            local found_admin = false
            local found_utility = false
            for _, c in ipairs(cats) do
                if c == 'admin' then found_admin = true end
                if c == 'utility' then found_utility = true end
            end
            assert.is_true(found_admin)
            assert.is_true(found_utility)
        end)
    end)
end)
