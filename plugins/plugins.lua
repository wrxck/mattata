--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local plugins = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')
local configuration = require('configuration')

function plugins:init(configuration)
    plugins.arguments = 'plugins <enable | disable> <plugin>'
    plugins.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('plugins').table
    plugins.help = '/plugins enable <plugin> - enable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.command_prefix .. 'plugins disable <plugin> - disable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.command_prefix .. 'plugins enable all - enable all of ' .. self.info.first_name .. '\'s non-core plugins in your group.\n' .. configuration.command_prefix .. 'plugins disable all - disable all of' .. self.info.first_name ..  '\'s non-core plugins in your group.\n' .. configuration.command_prefix .. 'plugins list - list all available plugins.'
end

local core_plugins = {
    'lua',
    'shell',
    'plugins',
    'control',
    'help',
    'setloc'
}

function plugins.is_plugin_existent(plugin)
    for k, v in pairs(core_plugins) do
        if plugin == v then
            return false
        end
    end
    for k, v in pairs(configuration.plugins) do
        if v == plugin then
            return true
        end
    end
    if plugin == 'ai' or plugin == 'telegram' or plugin == 'giphy' then
        return true
    end
    return false
end

function plugins.is_plugin_enabled(self, plugin)
    for k, v in pairs(enabled_plugins) do
        if plugin == v then
            return k
        end
    end
    return false
end

function plugins.enable_plugin(message, plugin)
    if not plugins.is_plugin_existent(plugin) then
        return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
    end
    if redis:hget(
        'chat:' .. message.chat.id .. ':disabled_plugins',
        plugin
    ) == 'true' then
        redis:hset(
            'chat:' .. message.chat.id .. ':disabled_plugins',
            plugin,
            false
        )
        return 'The plugin \'' .. plugin .. '\' has been enabled in this chat.'
    end
    return 'The plugin \'' .. plugin .. '\' has already been enabled in this chat!'
end

function plugins.disable_plugin(message, plugin)
    if not plugins.is_plugin_existent(plugin) then
        return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
    end
    if redis:hget(
        'chat:' .. message.chat.id .. ':disabled_plugins',
        plugin
    ) ~= 'true' then
        redis:hset(
            'chat:' .. message.chat.id .. ':disabled_plugins',
            plugin,
            true
        )
        return 'The plugin \'' .. plugin .. '\' has been disabled in this chat.'
    end
    return 'The plugin \'' .. plugin .. '\' has already been disabled in this chat!'
end

function plugins.disable_all(message)
    for k, v in pairs(configuration.plugins) do
        if plugins.is_plugin_existent(v) then
            if redis:hget(
                'chat:' .. message.chat.id .. ':disabled_plugins',
                v
            ) ~= 'true' then
                redis:hset(
                    'chat:' .. message.chat.id .. ':disabled_plugins',
                    v,
                    true
                )
            end
        end
    end
    return 'Success! Use \'' .. configuration.command_prefix .. 'plugins enable all\' to enable all of my plugins, or use \'' .. configuration.command_prefix .. 'plugins enable <plugin>\' to enable plugins individually.'
end

function plugins.list_disabled(message)
    local disabled_list = {}
    local disabled_count = 0
    for k, v in pairs(configuration.plugins) do
        if redis:hget(
            'chat:' .. message.chat.id .. ':disabled_plugins',
            v
        ) == 'true' then
            table.insert(
                disabled_list,
                v
            )
            disabled_count = disabled_count + 1
        end
    end
    if disabled_count == 0 then
        return 'You haven\'t disabled any plugins in this chat!'
    end
    table.sort(disabled_list)
    return 'The following plugins are disabled in this chat:\n' .. table.concat(
        disabled_list,
        ', '
    )
end

function plugins.list_enabled(message)
    local enabled_list = {}
    local enabled_count = 0
    for k, v in pairs(configuration.plugins) do
        if redis:hget(
            'chat:' .. message.chat.id .. ':disabled_plugins',
            v
        ) ~= 'true' and plugins.is_plugin_existent(v) then
            table.insert(
                enabled_list,
                v
            )
            enabled_count = enabled_count + 1
        end
    end
    if enabled_count == 0 then
        return 'You haven\'t enabled any plugins in this chat!'
    end
    table.sort(enabled_list)
    return 'The following plugins are enabled in this chat:\n' .. table.concat(
        enabled_list,
        ', '
    )
end

function plugins.enable_all(message)
    for k, v in pairs(configuration.plugins) do
        local disabled = redis:hget(
            'chat:' .. message.chat.id .. ':disabled_plugins',
            v
        )
        if disabled ~= 'false' then
            redis:hset(
                'chat:' .. message.chat.id .. ':disabled_plugins',
                v,
                false
            )
        end
    end
    return 'Success! Use \'' .. configuration.command_prefix .. 'plugins disable all\' to disable all plugins, or use \'' .. configuration.command_prefix .. 'plugins disable <plugin>\' to disable plugins individually.'
end

function plugins:on_message(message, configuration)
    if message.chat.type == 'private' then
        return mattata.send_reply(
            message,
            'This command cannot be used in private chat.'
        )
    elseif not mattata.is_group_admin(
        message.chat.id,
        message.from.id
    ) and not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'You must be an administrator of this chat in order to be able to use this command!'
        )
    end
    if message.text_lower:match('^' .. configuration.command_prefix .. 'plugins$') or message.text_lower:match('^' .. configuration.command_prefix .. 'plugins@' .. self.info.username .. '$') then
        return mattata.send_message(
            message.chat.id,
            '<b>Hello, ' .. mattata.escape_html(message.from.first_name) .. '!</b>\n\nTo disable a specific plugin, use \'' .. configuration.command_prefix .. 'plugins disable &lt;plugin&gt;\'. To enable a specific plugin, use \'' .. configuration.command_prefix .. 'plugins enable &lt;plugin&gt;\'.\n\nFor the sake of convenience, you can enable all of my non-core plugins by using \'' .. configuration.command_prefix .. 'plugins enable all\'. To disable all of my non-core plugins, you can use \'' .. configuration.command_prefix .. 'plugins disable all\'.\n\nTo see a list of plugins you\'ve disabled, use \'' .. configuration.command_prefix .. 'plugins disabled\'. For a list of plugins that can be toggled and haven\'t been disabled in this chat yet, use \'' .. configuration.command_prefix .. 'plugins enabled\'.\n\nA list of all toggleable plugins can be viewed by using \'' .. configuration.command_prefix .. 'plugins list\'.',
            'html'
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'plugins enable %a+$') then
        local plugin = message.text:gsub('^' .. configuration.command_prefix .. 'plugins enable ', '')
        local output
        if plugin == 'all' then
            output = plugins.enable_all(message)
        else
            output = plugins.enable_plugin(
                message,
                plugin
            )
        end
        return mattata.send_reply(
            message,
            output
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'plugins disable %a+$') then
        local plugin = message.text:gsub('^' .. configuration.command_prefix .. 'plugins disable ', '')
        local output
        if plugin:lower() == 'all' then
            output = plugins.disable_all(message)
        else
            output = plugins.disable_plugin(
                message,
                plugin
            )
        end
        return mattata.send_reply(
            message,
            output
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'plugins disabled$') then
        return mattata.send_message(
            message.chat.id,
            plugins.list_disabled(message)
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'plugins enabled$') then
        return mattata.send_message(
            message.chat.id,
            plugins.list_enabled(message)
        )
    elseif message.text_lower:match('^' .. configuration.command_prefix .. 'plugins list$') then
        local plugin_list = {}
        for k, v in pairs(configuration.plugins) do
            if plugins.is_plugin_existent(v) then
                table.insert(
                    plugin_list,
                    v
                )
            end
        end
        table.sort(plugin_list)
        return mattata.send_message(
            message.chat.id,
            'Toggleable plugins:\n' .. table.concat(
                plugin_list,
                ', '
            )
        )
    end
end

return plugins