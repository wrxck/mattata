--[[
Be sure this file has no dependencies
--]]

-- Returns all plugins ending with `extension` under
-- `directory`.
--
-- @tparam {string='plugins'} directory path to plugins folder
-- @treturn {array<string>} all available plugins
local get_plugin_list = function(directory)
    directory = directory and tostring(directory) or 'plugins'

    if directory:match('/$') then
        directory = directory:match('^(.-)/$')
    end

    local plugins = {}
    local handle = io.popen('ls ' .. directory .. '/')
    local result = handle:read('*all')
    handle:close()

    for plugin in result:gmatch('[%w_-]+%.lua ?') do
        plugin = plugin:match('^([%w_-]+)%.lua ?$')
        table.insert(plugins, plugin)
    end

    return plugins
end

local get_plugin_map = function(directory)
    local plugins = get_plugin_list(directory)
    local plugin_map = {}

    for _, name in pairs(plugins) do
        plugin_map[name] = true
    end

    return plugin_map
end

local load_plugin_list = function(plugins, directory)
    if plugins then
        plugin_map = get_plugin_map(directory)

        -- let's try to catch mistypes or missing files
        for _, plugin in pairs(plugins) do
            if not plugin_map[plugin] then
                error(string.format('cannot load plugin `%s` as it could not be found', plugin))
            end
        end
    else
        plugins = get_plugin_list(directory)
    end

    return plugins
end

-- Returns all folder names under /fonts
-- @treturn {array<string>}
local load_font_list = function()
    local fonts = {}
    local handle = io.popen('ls fonts/')
    local result = handle:read('*all')
    handle:close()

    for font in result:gmatch('%a+') do
        table.insert(fonts, font)
    end
    return fonts
end

return {
    load_plugin_list = load_plugin_list,
    load_font_list = load_font_list,
}