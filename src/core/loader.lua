--[[
    mattata v2.0 - Plugin Loader
    Discovers, validates, and manages plugins from category directories.
    Supports hot-reload and per-chat enable/disable.
]]

local loader = {}

local logger = require('src.core.logger')

local plugins = {}          -- ordered list of all loaded plugins
local by_command = {}        -- command -> plugin lookup
local by_name = {}           -- name -> plugin lookup
local categories = {}        -- category -> list of plugin names
local by_event = {}          -- event_name -> list of plugins with that handler

local PERMANENT_PLUGINS = { 'help', 'about', 'plugins' }
local PERMANENT_SET = { help = true, about = true, plugins = true }

-- Event handler names to index for fast dispatch
local INDEXED_EVENTS = {
    'on_new_message', 'on_member_join', 'on_callback_query', 'on_inline_query',
    'on_chat_join_request', 'on_chat_member_update', 'on_my_chat_member',
    'on_reaction', 'on_reaction_count', 'on_chat_boost', 'on_removed_chat_boost',
    'on_poll', 'on_poll_answer', 'cron'
}

local CATEGORIES = { 'admin', 'utility', 'fun', 'media', 'ai' }

-- Build event index from current plugin list
local function rebuild_event_index()
    by_event = {}
    for _, event in ipairs(INDEXED_EVENTS) do
        by_event[event] = {}
    end
    for _, plugin in ipairs(plugins) do
        for _, event in ipairs(INDEXED_EVENTS) do
            if plugin[event] then
                table.insert(by_event[event], plugin)
            end
        end
    end
end

function loader.init(_, _, _)
    plugins = {}
    by_command = {}
    by_name = {}
    categories = {}
    by_event = {}

    for _, category in ipairs(CATEGORIES) do
        categories[category] = {}
        local manifest_path = 'src.plugins.' .. category .. '.init'
        local ok, manifest = pcall(require, manifest_path)
        if ok and type(manifest) == 'table' and manifest.plugins then
            for _, plugin_name in ipairs(manifest.plugins) do
                local plugin_path = 'src.plugins.' .. category .. '.' .. plugin_name
                local load_ok, plugin = pcall(require, plugin_path)
                if load_ok and type(plugin) == 'table' then
                    plugin.name = plugin.name or plugin_name
                    plugin.category = plugin.category or category
                    plugin.commands = plugin.commands or {}
                    plugin.help = plugin.help or ''
                    plugin.description = plugin.description or ''

                    table.insert(plugins, plugin)
                    by_name[plugin.name] = plugin
                    table.insert(categories[category], plugin.name)

                    -- Index commands for fast lookup
                    for _, cmd in ipairs(plugin.commands) do
                        by_command[cmd:lower()] = plugin
                    end

                    logger.debug('Loaded plugin: %s/%s (%d commands)', category, plugin.name, #plugin.commands)
                else
                    logger.warn('Failed to load plugin %s/%s: %s', category, plugin_name, tostring(plugin))
                end
            end
        else
            logger.debug('No manifest for category: %s (%s)', category, tostring(manifest))
        end
    end

    rebuild_event_index()
    logger.info('Loaded %d plugins across %d categories', #plugins, #CATEGORIES)
end

-- Get all loaded plugins (ordered)
function loader.get_plugins()
    return plugins
end

-- Look up a plugin by command name
function loader.get_by_command(command)
    return by_command[command:lower()]
end

-- Look up a plugin by name
function loader.get_by_name(name)
    return by_name[name]
end

-- Get all plugins in a category
function loader.get_category(category)
    local result = {}
    for _, name in ipairs(categories[category] or {}) do
        table.insert(result, by_name[name])
    end
    return result
end

-- Count loaded plugins
function loader.count()
    return #plugins
end

-- Check if a plugin is permanent (cannot be disabled)
function loader.is_permanent(name)
    return PERMANENT_SET[name] or false
end

-- Get plugins that implement a specific event handler
function loader.get_by_event(event_name)
    return by_event[event_name] or {}
end

-- Hot-reload a plugin by name
function loader.reload(name)
    local plugin = by_name[name]
    if not plugin then
        return false, 'Plugin not found: ' .. name
    end

    local path = 'src.plugins.' .. plugin.category .. '.' .. name
    package.loaded[path] = nil

    local ok, new_plugin = pcall(require, path)
    if not ok then
        return false, 'Reload failed: ' .. tostring(new_plugin)
    end

    -- Preserve metadata
    new_plugin.name = name
    new_plugin.category = plugin.category
    new_plugin.commands = new_plugin.commands or {}

    -- Replace in ordered list
    for i, p in ipairs(plugins) do
        if p.name == name then
            plugins[i] = new_plugin
            break
        end
    end

    -- Re-index commands (remove old, add new)
    for cmd, p in pairs(by_command) do
        if p.name == name then
            by_command[cmd] = nil
        end
    end
    for _, cmd in ipairs(new_plugin.commands) do
        by_command[cmd:lower()] = new_plugin
    end

    by_name[name] = new_plugin
    rebuild_event_index()
    logger.info('Hot-reloaded plugin: %s', name)
    return true
end

-- Get help text for all plugins or a specific category
function loader.get_help(category, chat_id)
    local help = {}
    local source = category and loader.get_category(category) or plugins
    for _, plugin in ipairs(source) do
        if plugin.help and plugin.help ~= '' then
            table.insert(help, {
                name = plugin.name,
                category = plugin.category,
                commands = plugin.commands,
                help = plugin.help,
                description = plugin.description
            })
        end
    end
    return help
end

-- Get list of categories
function loader.get_categories()
    return CATEGORIES
end

return loader
